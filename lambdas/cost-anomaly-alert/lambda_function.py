"""
Cost Anomaly Alert — AWS Lambda

Monitors AWS spending via Cost Explorer API.
- Daily cost check with day-over-day comparison
- Weekly report (Monday): this week vs last week
- Monthly forecast based on current burn rate
- Cost breakdown by tag (team, env, etc.)

NOTE: Cost Explorer API must be called from us-east-1.
"""
import json
import os
from datetime import datetime, timedelta, timezone

import boto3

import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "shared"))
import notifier

DAILY_THRESHOLD = float(os.environ.get("DAILY_THRESHOLD", "100"))
GROUP_BY_TAG = os.environ.get("GROUP_BY_TAG", "team")
MODE = os.environ.get("MODE", "daily")  # daily | weekly

ce = boto3.client("ce", region_name="us-east-1")


def get_cost(start, end, group_by_tag=None):
    params = dict(TimePeriod={"Start": start, "End": end}, Granularity="DAILY",
                  Metrics=["UnblendedCost"])
    if group_by_tag:
        params["GroupBy"] = [{"Type": "TAG", "Key": group_by_tag}]
    return ce.get_cost_and_usage(**params)


def daily_check():
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    yesterday = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d")
    day_before = (datetime.now(timezone.utc) - timedelta(days=2)).strftime("%Y-%m-%d")

    resp = get_cost(day_before, today)
    costs = []
    for r in resp["ResultsByTime"]:
        costs.append(float(r["Total"]["UnblendedCost"]["Amount"]))

    if len(costs) < 2:
        return
    prev, curr = costs[0], costs[1]
    change_pct = ((curr - prev) / prev * 100) if prev > 0 else 0

    # Monthly forecast
    day_of_month = datetime.now(timezone.utc).day
    days_in_month = 30
    forecast = (curr * days_in_month / day_of_month) if day_of_month > 0 else 0

    # Tag breakdown
    tag_resp = get_cost(yesterday, today, group_by_tag=GROUP_BY_TAG)
    tag_lines = []
    for r in tag_resp["ResultsByTime"]:
        for g in r.get("Groups", []):
            tag_val = g["Keys"][0].replace(f"{GROUP_BY_TAG}$", "") or "(untagged)"
            amt = float(g["Metrics"]["UnblendedCost"]["Amount"])
            if amt > 1:
                tag_lines.append(f"  {tag_val}: ${amt:.2f}")

    if curr > DAILY_THRESHOLD or abs(change_pct) > 30:
        lines = [
            f"Yesterday: **${curr:.2f}** ({'+' if change_pct > 0 else ''}{change_pct:.0f}% vs day before)",
            f"Day before: ${prev:.2f}",
            f"Monthly forecast: **${forecast:.0f}**",
        ]
        if tag_lines:
            lines.append(f"\nBy {GROUP_BY_TAG}:")
            lines.extend(tag_lines)
        notifier.send("💸 AWS Cost Alert", "\n".join(lines))


def weekly_report():
    today = datetime.now(timezone.utc)
    this_mon = today - timedelta(days=today.weekday())
    last_mon = this_mon - timedelta(days=7)
    prev_mon = last_mon - timedelta(days=7)

    this_week = get_cost(last_mon.strftime("%Y-%m-%d"), this_mon.strftime("%Y-%m-%d"))
    last_week = get_cost(prev_mon.strftime("%Y-%m-%d"), last_mon.strftime("%Y-%m-%d"))

    def sum_cost(resp):
        return sum(float(r["Total"]["UnblendedCost"]["Amount"]) for r in resp["ResultsByTime"])

    tw = sum_cost(this_week)
    lw = sum_cost(last_week)
    change = ((tw - lw) / lw * 100) if lw > 0 else 0

    lines = [
        f"Last week: **${tw:.2f}**",
        f"Week before: ${lw:.2f}",
        f"Change: {'+' if change > 0 else ''}{change:.1f}%",
    ]
    notifier.send("📊 AWS Weekly Cost Report", "\n".join(lines))


def lambda_handler(event, context):
    if MODE == "weekly" or (datetime.now(timezone.utc).weekday() == 0 and MODE == "daily"):
        weekly_report()
    daily_check()
    return {"statusCode": 200}

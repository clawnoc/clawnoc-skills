"""
SSL Certificate Expiry Checker — AWS Lambda

Checks TLS certificate expiry for a list of domains.
Alerts when certificates expire within WARN_DAYS (default 30).
"""
import json
import os
import socket
import ssl
from datetime import datetime, timezone

# Allow shared notifier to be imported both locally and in Lambda
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "shared"))
import notifier

DOMAINS = [d.strip() for d in os.environ.get("DOMAINS", "example.com").split(",") if d.strip()]
WARN_DAYS = int(os.environ.get("WARN_DAYS", "30"))


def check_cert(domain: str, port: int = 443) -> dict:
    ctx = ssl.create_default_context()
    try:
        with socket.create_connection((domain, port), timeout=10) as sock:
            with ctx.wrap_socket(sock, server_hostname=domain) as ssock:
                cert = ssock.getpeercert()
        expiry = datetime.strptime(cert["notAfter"], "%b %d %H:%M:%S %Y %Z").replace(tzinfo=timezone.utc)
        days = (expiry - datetime.now(timezone.utc)).days
        return {"domain": domain, "expiry": expiry.strftime("%Y-%m-%d"), "days": days, "error": None}
    except Exception as e:
        return {"domain": domain, "expiry": None, "days": -1, "error": str(e)}


def lambda_handler(event, context):
    results = [check_cert(d) for d in DOMAINS]
    warnings = [r for r in results if r["days"] <= WARN_DAYS]

    if warnings:
        lines = []
        for r in warnings:
            if r["error"]:
                lines.append(f"❌ {r['domain']} — Error: {r['error']}")
            else:
                lines.append(f"⚠️ {r['domain']} — Expires: {r['expiry']} ({r['days']} days)")
        notifier.send("🔒 SSL Certificate Expiry Alert", "\n".join(lines))

    return {"statusCode": 200, "body": json.dumps(results, default=str)}

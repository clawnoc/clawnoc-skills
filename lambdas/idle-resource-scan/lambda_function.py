"""
Idle Resource Scanner — AWS Lambda

Detects underutilized AWS resources:
- EC2: CPU < 5% for 7 days
- RDS: CPU < 5% for 7 days
- EBS: Unattached volumes
- EIP: Unassociated Elastic IPs
- NAT Gateway: < 1GB traffic in 7 days
"""
import json
import os
from datetime import datetime, timedelta, timezone

import boto3

import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "shared"))
import notifier

DAYS = int(os.environ.get("LOOKBACK_DAYS", "7"))
CPU_THRESHOLD = float(os.environ.get("CPU_THRESHOLD", "5.0"))
NAT_BYTES_THRESHOLD = int(os.environ.get("NAT_BYTES_THRESHOLD", str(1 * 1024**3)))  # 1GB

cw = boto3.client("cloudwatch")
ec2 = boto3.client("ec2")
rds = boto3.client("rds")


def avg_metric(namespace, metric, dimensions, stat="Average"):
    end = datetime.now(timezone.utc)
    start = end - timedelta(days=DAYS)
    resp = cw.get_metric_statistics(
        Namespace=namespace, MetricName=metric, Dimensions=dimensions,
        StartTime=start, EndTime=end, Period=86400, Statistics=[stat],
    )
    points = resp.get("Datapoints", [])
    if not points:
        return None
    return sum(p[stat] for p in points) / len(points)


def scan_ec2():
    findings = []
    instances = ec2.describe_instances(Filters=[{"Name": "instance-state-name", "Values": ["running"]}])
    for r in instances["Reservations"]:
        for i in r["Instances"]:
            iid = i["InstanceId"]
            itype = i.get("InstanceType", "?")
            cpu = avg_metric("AWS/EC2", "CPUUtilization", [{"Name": "InstanceId", "Value": iid}])
            if cpu is not None and cpu < CPU_THRESHOLD:
                name = next((t["Value"] for t in i.get("Tags", []) if t["Key"] == "Name"), "")
                findings.append(f"EC2 `{iid}` ({itype}) {name} — CPU avg {cpu:.1f}%")
    return findings


def scan_rds():
    findings = []
    for db in rds.describe_db_instances()["DBInstances"]:
        dbid = db["DBInstanceIdentifier"]
        cpu = avg_metric("AWS/RDS", "CPUUtilization", [{"Name": "DBInstanceIdentifier", "Value": dbid}])
        if cpu is not None and cpu < CPU_THRESHOLD:
            findings.append(f"RDS `{dbid}` ({db['DBInstanceClass']}) — CPU avg {cpu:.1f}%")
    return findings


def scan_ebs():
    findings = []
    vols = ec2.describe_volumes(Filters=[{"Name": "status", "Values": ["available"]}])
    for v in vols["Volumes"]:
        findings.append(f"EBS `{v['VolumeId']}` {v['Size']}GB ({v['VolumeType']}) — unattached")
    return findings


def scan_eip():
    findings = []
    for addr in ec2.describe_addresses()["Addresses"]:
        if "InstanceId" not in addr and "NetworkInterfaceId" not in addr:
            findings.append(f"EIP `{addr['PublicIp']}` ({addr['AllocationId']}) — unassociated")
    return findings


def scan_nat():
    findings = []
    gws = ec2.describe_nat_gateways(Filter=[{"Name": "state", "Values": ["available"]}])
    for gw in gws["NatGateways"]:
        gid = gw["NatGatewayId"]
        bytes_out = avg_metric("AWS/NATGateway", "BytesOutToDestination",
                               [{"Name": "NatGatewayId", "Value": gid}], stat="Sum")
        if bytes_out is not None and bytes_out * DAYS < NAT_BYTES_THRESHOLD:
            findings.append(f"NAT `{gid}` — {bytes_out * DAYS / 1024**2:.0f}MB in {DAYS}d (< 1GB)")
    return findings


def lambda_handler(event, context):
    all_findings = []
    for label, scanner in [("EC2", scan_ec2), ("RDS", scan_rds), ("EBS", scan_ebs), ("EIP", scan_eip), ("NAT", scan_nat)]:
        try:
            all_findings.extend(scanner())
        except Exception as e:
            all_findings.append(f"⚠️ {label} scan error: {e}")

    if all_findings:
        body = f"Found {len(all_findings)} idle resources:\n" + "\n".join(f"• {f}" for f in all_findings)
        notifier.send("💰 Idle Resource Alert", body)

    return {"statusCode": 200, "body": json.dumps({"findings": all_findings})}

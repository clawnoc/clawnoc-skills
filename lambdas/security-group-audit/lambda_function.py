"""
Security Group Audit — AWS Lambda

Scans all security groups for risky inbound rules:
- 0.0.0.0/0 or ::/0 on sensitive ports (SSH, RDP, DB)
- Overly permissive rules (all traffic)
- Shows associated EC2 instances
- Provides fix commands
"""
import json
import os

import boto3

import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "shared"))
import notifier

WHITELIST = set(os.environ.get("WHITELIST_SG_IDS", "").split(",")) - {""}
SENSITIVE_PORTS = {22: "SSH", 3389: "RDP", 3306: "MySQL", 5432: "PostgreSQL",
                   6379: "Redis", 27017: "MongoDB", 9200: "Elasticsearch"}

ec2 = boto3.client("ec2")


def get_sg_instances():
    """Map security group IDs to associated instance IDs."""
    sg_map = {}
    paginator = ec2.get_paginator("describe_instances")
    for page in paginator.paginate():
        for r in page["Reservations"]:
            for i in r["Instances"]:
                iid = i["InstanceId"]
                name = next((t["Value"] for t in i.get("Tags", []) if t["Key"] == "Name"), "")
                for sg in i.get("SecurityGroups", []):
                    sg_map.setdefault(sg["GroupId"], []).append(f"{iid} ({name})" if name else iid)
    return sg_map


def audit():
    sg_instances = get_sg_instances()
    findings = []

    for sg in ec2.describe_security_groups()["SecurityGroups"]:
        sgid = sg["GroupId"]
        if sgid in WHITELIST:
            continue
        sg_name = sg.get("GroupName", "")

        for rule in sg.get("IpPermissions", []):
            from_port = rule.get("FromPort", 0)
            to_port = rule.get("ToPort", 65535)
            protocol = rule.get("IpProtocol", "-1")

            open_cidrs = [r["CidrIp"] for r in rule.get("IpRanges", []) if r["CidrIp"] in ("0.0.0.0/0", "::/0")]
            open_cidrs += [r["CidrIpv6"] for r in rule.get("Ipv6Ranges", []) if r["CidrIpv6"] == "::/0"]

            if not open_cidrs:
                continue

            # Determine risk
            if protocol == "-1":
                risk = "CRITICAL"
                desc = "All traffic open to internet"
                fix = f"aws ec2 revoke-security-group-ingress --group-id {sgid} --protocol -1 --cidr 0.0.0.0/0"
            elif from_port in SENSITIVE_PORTS or to_port in SENSITIVE_PORTS:
                port = from_port if from_port in SENSITIVE_PORTS else to_port
                svc = SENSITIVE_PORTS[port]
                risk = "HIGH"
                desc = f"{svc} (port {port}) open to internet"
                fix = f"aws ec2 revoke-security-group-ingress --group-id {sgid} --protocol tcp --port {port} --cidr 0.0.0.0/0"
            else:
                risk = "MEDIUM"
                desc = f"Port {from_port}-{to_port} open to internet"
                fix = f"aws ec2 revoke-security-group-ingress --group-id {sgid} --protocol tcp --port {from_port} --cidr 0.0.0.0/0"

            instances = sg_instances.get(sgid, ["(no instances)"])
            findings.append({
                "sg_id": sgid, "sg_name": sg_name, "risk": risk,
                "desc": desc, "fix": fix, "instances": instances[:5],
            })

    return findings


def lambda_handler(event, context):
    findings = audit()

    if findings:
        lines = [f"Found **{len(findings)}** risky security group rules:\n"]
        for f in findings[:15]:
            inst_str = ", ".join(f["instances"])
            lines.append(f"[{f['risk']}] `{f['sg_id']}` ({f['sg_name']})")
            lines.append(f"  → {f['desc']}")
            lines.append(f"  → Instances: {inst_str}")
            lines.append(f"  → Fix: `{f['fix']}`\n")
        notifier.send("🛡️ Security Group Audit", "\n".join(lines))

    return {"statusCode": 200, "body": json.dumps({"findings": len(findings)})}

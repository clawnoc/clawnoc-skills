"""
Pluggable notification module.
Supports DingTalk, Feishu (Lark), and Slack webhooks.
Set NOTIFY_TYPE env var to: dingtalk | feishu | slack
Set WEBHOOK_URL env var to the webhook endpoint.
"""
import json
import os
import urllib.request


NOTIFY_TYPE = os.environ.get("NOTIFY_TYPE", "slack")
WEBHOOK_URL = os.environ.get("WEBHOOK_URL", "")


def send(title: str, body: str) -> bool:
    if not WEBHOOK_URL:
        print(f"[notify] WEBHOOK_URL not set, printing to stdout:\n{title}\n{body}")
        return False

    builders = {"dingtalk": _dingtalk, "feishu": _feishu, "slack": _slack}
    payload = builders.get(NOTIFY_TYPE, _slack)(title, body)

    req = urllib.request.Request(
        WEBHOOK_URL,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    try:
        urllib.request.urlopen(req, timeout=10)
        return True
    except Exception as e:
        print(f"[notify] Failed: {e}")
        return False


def _dingtalk(title, body):
    return {"msgtype": "markdown", "markdown": {"title": title, "text": f"## {title}\n{body}"}}


def _feishu(title, body):
    return {"msg_type": "interactive", "card": {
        "header": {"title": {"tag": "plain_text", "content": title}},
        "elements": [{"tag": "markdown", "content": body}],
    }}


def _slack(title, body):
    return {"text": f"*{title}*\n{body}"}

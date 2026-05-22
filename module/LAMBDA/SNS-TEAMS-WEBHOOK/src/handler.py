import json
import os
import urllib.error
import urllib.request

WEBHOOK_URL = os.environ["TEAMS_WEBHOOK_URL"]

THEME_COLORS = {
    "ALARM": "FF0000",
    "OK": "00FF00",
    "INSUFFICIENT_DATA": "FFA500",
}

STATE_LABELS = {
    "ALARM": "🚨 ALARM",
    "OK": "✅ OK",
    "INSUFFICIENT_DATA": "⚠️ INSUFFICIENT DATA",
}


def lambda_handler(event, context):
    for record in event["Records"]:
        sns_message = record["Sns"]["Message"]
        try:
            alarm = json.loads(sns_message)
        except json.JSONDecodeError:
            alarm = {"AlarmName": "Unknown", "NewStateValue": "UNKNOWN", "NewStateReason": sns_message}
        post_to_teams(alarm)


def post_to_teams(alarm):
    state = alarm.get("NewStateValue", "UNKNOWN")
    alarm_name = alarm.get("AlarmName", "Unknown Alarm")
    description = alarm.get("AlarmDescription", "")
    region = alarm.get("Region", "")
    reason = alarm.get("NewStateReason", "")
    timestamp = alarm.get("StateChangeTime", "")

    color = THEME_COLORS.get(state, "808080")
    label = STATE_LABELS.get(state, state)

    facts = [{"name": "Status", "value": label}]
    if region:
        facts.append({"name": "Region", "value": region})
    if timestamp:
        facts.append({"name": "Time", "value": timestamp})
    if reason:
        facts.append({"name": "Reason", "value": reason})

    payload = {
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": color,
        "summary": f"{alarm_name} — {state}",
        "sections": [
            {
                "activityTitle": f"**{alarm_name}**",
                "activitySubtitle": description,
                "facts": facts,
                "markdown": True,
            }
        ],
    }

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        WEBHOOK_URL,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            print(f"Teams response: {resp.status} for alarm {alarm_name}")
    except urllib.error.HTTPError as e:
        print(f"Teams webhook HTTP error: {e.code} {e.reason}")
        raise

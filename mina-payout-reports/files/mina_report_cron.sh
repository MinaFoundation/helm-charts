#!/bin/bash

: "${EPOCH_API:?Environment variable EPOCH_API must be set}"
: "${REPORT_API:?Environment variable REPORT_API must be set}"
: "${SLACK_WEBHOOK:?Environment variable SLACK_WEBHOOK must be set}"

# Function to send Slack message
send_slack() {
  local message="$1"
  curl -s -X POST "$SLACK_WEBHOOK" \
    -H "Content-type: application/json" \
    -d "{\"text\":\"$message\"}" > /dev/null
}

while true; do
  response=$(curl -s "$EPOCH_API")
  slot=$(echo "$response" | jq -r '.slot')
  epoch=$(echo "$response" | jq -r '.epoch')
  epoch=$((epoch - 1))

  echo "Slot: $slot | Epoch: $epoch"

  if [ "$slot" == "100" ]; then
    msg="Triggering obligation report for slot 100"
    echo "$msg"
    send_slack "$msg"

    resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$REPORT_API" \
      -H "Content-Type: application/json" \
      -d "{\"epoch_no\": $epoch, \"report_type\": \"obligation_report_slot_100\"}")

    if [ "$resp" == "200" ]; then
      send_slack "✅ Obligation report for slot 100 successfully triggered"
    else
      send_slack "❌ Failed to trigger obligation report for slot 100 (HTTP $resp)"
    fi

    sleep 600  # 10 minutes

  elif [ "$slot" == "3500" ]; then
    msg="Triggering validation report for slot 3500"
    echo "$msg"
    send_slack "$msg"

    resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$REPORT_API" \
      -H "Content-Type: application/json" \
      -d "{\"epoch_no\": $epoch, \"report_type\": \"validation_report_slot_3500\"}")

    if [ "$resp" == "200" ]; then
      send_slack "✅ Validation report for slot 3500 successfully triggered"
    else
      send_slack "❌ Failed to trigger validation report for slot 3500 (HTTP $resp)"
    fi

    sleep 600  # 10 minutes

  else
    echo "No action needed. Sleeping 1 minute..."
    sleep 60
  fi
done

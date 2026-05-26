#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

: "${TRMNL_WEBHOOK_URL:?Set TRMNL_WEBHOOK_URL}"
TRMNL_REMINDERS_LIST="${TRMNL_REMINDERS_LIST:-Reminders}"
TRMNL_PAYLOAD_FORMAT="${TRMNL_PAYLOAD_FORMAT:-legacy}"

exec .build/release/trmnl-apple-reminders-sender \
  --webhook "$TRMNL_WEBHOOK_URL" \
  --list "$TRMNL_REMINDERS_LIST" \
  --format "$TRMNL_PAYLOAD_FORMAT"

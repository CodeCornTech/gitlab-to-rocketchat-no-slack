#!/usr/bin/env bash
# Send a harmless sample notification to Rocket.Chat.
# The secret webhook URL is read silently and never stored to disk.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAYLOAD="$ROOT/examples/payload.json"

if ! command -v curl >/dev/null 2>&1; then
  printf 'ERROR: curl is required.\n' >&2
  exit 1
fi
if [[ ! -r "$PAYLOAD" ]]; then
  printf 'ERROR: payload file not found: %s\n' "$PAYLOAD" >&2
  exit 1
fi

# Optionally accept a value through the environment for CI/local testing.
# Interactive input is preferable for human users because it does not echo.
WEBHOOK_URL="${ROCKETCHAT_WEBHOOK_URL:-}"
unset ROCKETCHAT_WEBHOOK_URL  # Do not pass an inherited token to the curl subprocess.
if [[ -z "$WEBHOOK_URL" ]]; then
  if [[ ! -r /dev/tty ]]; then
    printf 'ERROR: interactive terminal unavailable. Set ROCKETCHAT_WEBHOOK_URL securely.\n' >&2
    exit 1
  fi
  printf 'Rocket.Chat webhook URL (hidden): ' >/dev/tty
  IFS= read -r -s WEBHOOK_URL </dev/tty
  printf '\n' >/dev/tty
fi

# Require HTTPS and reject whitespace, quotes, or embedded newlines (curl config safety).
if [[ ! "$WEBHOOK_URL" =~ ^https://[^[:space:]\"]+$ ]]; then
  printf 'ERROR: expected a valid HTTPS webhook URL.\n' >&2
  exit 1
fi
# Also avoid backslashes, which have special meaning inside curl config strings.
if [[ "$WEBHOOK_URL" == *'\'* ]]; then
  printf 'ERROR: invalid character in URL.\n' >&2
  exit 1
fi

RESPONSE="$(mktemp)"
trap 'rm -f "$RESPONSE"' EXIT

# Feeding the URL to curl via --config stdin keeps it out of the process argv.
# The JSON payload is read from a static, non-secret file.
set +e
HTTP_CODE="$(printf 'url = "%s"\n' "$WEBHOOK_URL" | \
  curl --config - --silent --show-error \
    --output "$RESPONSE" --write-out '%{http_code}' \
    --request POST --header 'Content-Type: application/json' \
    --data-binary "@$PAYLOAD")"
CURL_EXIT=$?
set -e

unset WEBHOOK_URL
printf 'HTTP %s\n' "${HTTP_CODE:-000}"
if (( CURL_EXIT != 0 )) || [[ ! "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
  printf 'ERROR: Rocket.Chat request failed (curl exit %s).\n' "$CURL_EXIT" >&2
  # Deliberately do not print response bodies; they can contain sensitive data.
  exit 1
fi

# Some implementations return HTTP 200 with an application-level error.
if grep -Eq '"success"[[:space:]]*:[[:space:]]*false' "$RESPONSE"; then
  printf 'ERROR: Rocket.Chat reported success:false.\n' >&2
  exit 1
fi

printf 'Accepted by endpoint. Confirm that the message appeared in your channel.\n'
printf 'Next: run Test settings in GitLab to verify GitLab → Rocket.Chat end to end.\n'

#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] HOST PORT

Positional:
  HOST        Server address (e.g. 127.0.0.1 or myhost.local)
  PORT        Server port   (e.g. 8080)

Options:
  --model=NAME     Model name to request  (default: default)
  --api-key=KEY    API key to send        (default: none)
  --system=TEXT    System prompt          (default: none)
  -h, --help       Show this help

Examples:
  $(basename "$0") 127.0.0.1 8080
  $(basename "$0") --model=llama3 --api-key=sk-xxx 192.168.1.10 11434
EOF
    exit 0
}

MODEL="default"
API_KEY="none"
SYSTEM_PROMPT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model=*)   MODEL="${1#*=}";        shift ;;
        --api-key=*) API_KEY="${1#*=}";      shift ;;
        --system=*)  SYSTEM_PROMPT="${1#*=}"; shift ;;
        -h|--help)   usage ;;
        -*)          echo "Unknown option: $1" >&2; exit 1 ;;
        *)           break ;;
    esac
done

if [[ $# -lt 2 ]]; then
    echo "Error: HOST and PORT are required." >&2
    echo "Run with --help for usage." >&2
    exit 1
fi

HOST="$1"
PORT="$2"
BASE_URL="http://${HOST}:${PORT}/v1/chat/completions"

# history is a JSON array of message objects, built up across turns
HISTORY="[]"

if [[ -n "$SYSTEM_PROMPT" ]]; then
    SYSTEM_JSON=$(printf '%s' "$SYSTEM_PROMPT" | jq -Rs '.')
    HISTORY=$(printf '[{"role":"system","content":%s}]' "$SYSTEM_JSON")
fi

echo "Connected to ${BASE_URL}  model=${MODEL}"
echo "Type your message and press Enter. Ctrl-D or Ctrl-C to exit."
echo "---"

trap 'echo; echo "Bye."; exit 0' INT

while true; do
    printf "You: "
    if ! IFS= read -r USER_INPUT; then
        echo
        echo "Bye."
        break
    fi

    [[ -z "$USER_INPUT" ]] && continue

    USER_JSON=$(printf '%s' "$USER_INPUT" | jq -Rs '.')
    HISTORY=$(printf '%s' "$HISTORY" | jq --argjson msg "{\"role\":\"user\",\"content\":${USER_JSON}}" '. + [$msg]')

    PAYLOAD=$(jq -n \
        --arg model "$MODEL" \
        --argjson messages "$HISTORY" \
        '{"model": $model, "messages": $messages}')

    HTTP_BODY=$(curl -s -w '\n%{http_code}' \
        -X POST "$BASE_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${API_KEY}" \
        -d "$PAYLOAD")
    CURL_EXIT=$?
    HTTP_STATUS=$(printf '%s' "$HTTP_BODY" | tail -n1)
    RESPONSE=$(printf '%s' "$HTTP_BODY" | sed '$d')

    if [[ $CURL_EXIT -ne 0 ]]; then
        echo "[Error: curl failed (exit ${CURL_EXIT}) — server unreachable or connection refused]" >&2
        continue
    fi
    if [[ "$HTTP_STATUS" != "200" ]]; then
        echo "[Error: HTTP ${HTTP_STATUS}]" >&2
        echo "$RESPONSE" >&2
        continue
    fi

    REPLY=$(printf '%s' "$RESPONSE" | jq -r '.choices[0].message.content // "[Error: no content in response]"')

    echo "Assistant: ${REPLY}"
    echo

    REPLY_JSON=$(printf '%s' "$REPLY" | jq -Rs '.')
    HISTORY=$(printf '%s' "$HISTORY" | jq --argjson msg "{\"role\":\"assistant\",\"content\":${REPLY_JSON}}" '. + [$msg]')
done

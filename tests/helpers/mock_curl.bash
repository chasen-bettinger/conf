#!/usr/bin/env bash
# Mock curl that serves fixtures from FIXTURES_DIR by URL last-segment.
# Honors -o (output to file). Logs every URL to MOCK_CURL_LOG (one per line).
# Test knobs:
#   FIXTURES_DIR        directory to read fixtures from (required)
#   MOCK_CURL_LOG       path to append-log every URL to (optional)
#   MOCK_CURL_DENY      newline-separated URL substrings; matches 404
#   MOCK_CURL_MAP       file with "URL FIXTURE_FILENAME" lines; overrides default mapping

set -e

OUTPUT=""
URL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o)
            OUTPUT="$2"; shift 2 ;;
        -*)
            shift ;;
        *)
            URL="$1"; shift ;;
    esac
done

if [[ -n "${MOCK_CURL_LOG:-}" ]]; then
    echo "$URL" >> "$MOCK_CURL_LOG"
fi

if [[ -z "$URL" ]]; then
    exit 22
fi

if [[ -n "${MOCK_CURL_DENY:-}" ]]; then
    while IFS= read -r pattern; do
        [[ -z "$pattern" ]] && continue
        if [[ "$URL" == *"$pattern"* ]]; then
            exit 22
        fi
    done <<< "$MOCK_CURL_DENY"
fi

FIXTURE_NAME=""
if [[ -n "${MOCK_CURL_MAP:-}" && -f "${MOCK_CURL_MAP}" ]]; then
    FIXTURE_NAME=$(awk -v url="$URL" '$1 == url {print $2; exit}' "$MOCK_CURL_MAP")
fi

if [[ -z "$FIXTURE_NAME" ]]; then
    FIXTURE_NAME="${URL##*/}"
fi

FIXTURE_PATH="${FIXTURES_DIR}/${FIXTURE_NAME}"
if [[ ! -f "$FIXTURE_PATH" ]]; then
    exit 22
fi

if [[ -n "$OUTPUT" ]]; then
    cp "$FIXTURE_PATH" "$OUTPUT"
else
    cat "$FIXTURE_PATH"
fi

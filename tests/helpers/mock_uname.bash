#!/usr/bin/env bash
# Mock uname. Returns MOCK_UNAME_S for -s and MOCK_UNAME_M for -m.
# Falls back to the real uname for any other invocation.

case "$1" in
    -s) echo "${MOCK_UNAME_S:-Linux}" ;;
    -m) echo "${MOCK_UNAME_M:-x86_64}" ;;
    *)  exec /usr/bin/uname "$@" ;;
esac

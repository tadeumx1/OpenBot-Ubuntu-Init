#!/usr/bin/env bash
# Open the browser-only local session. This deliberately avoids openbot://,
# which is a protocol for the separate desktop app and is not installed on Ubuntu.

. "$(dirname "$0")/require-bash.sh"

set -euo pipefail

app_mode=false
case "${1:-}" in
  '') ;;
  --app) app_mode=true ;;
  -h|--help)
    printf '%s\n' 'Usage: bash scripts/open-openbot.sh [--app]'
    exit 0
    ;;
  *)
    printf 'Unknown option: %s\n' "$1" >&2
    exit 1
    ;;
esac

cd "$(dirname "$0")/.."

token="$({ grep -E '^OPENBOT_INSTALL_TOKEN=' .env || true; } | tail -1 | cut -d= -f2- | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/")"
if [ -z "$token" ]; then
  printf '%s\n' "OPENBOT_INSTALL_TOKEN is missing. Start OpenBot first: make start-local" >&2
  exit 1
fi

# The token stays out of the terminal output and browser history messages. It only establishes
# the local browser session and then redirects to the normal home page.
url="http://localhost:3010/api/install/enter?token=${token}&to=/"

if [ "$app_mode" = true ] && command -v google-chrome >/dev/null 2>&1; then
  google-chrome --app="$url" >/dev/null 2>&1 &
elif [ "$app_mode" = true ] && command -v google-chrome-stable >/dev/null 2>&1; then
  google-chrome-stable --app="$url" >/dev/null 2>&1 &
elif command -v google-chrome >/dev/null 2>&1; then
  google-chrome --new-tab "$url" >/dev/null 2>&1 &
elif command -v google-chrome-stable >/dev/null 2>&1; then
  google-chrome-stable --new-tab "$url" >/dev/null 2>&1 &
else
  xdg-open "$url" >/dev/null 2>&1 &
fi

printf '%s\n' "OpenBot opening in the browser at http://localhost:3010"

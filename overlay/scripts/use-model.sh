#!/usr/bin/env bash
# Select exactly one OpenBot model connection and optionally restart the stack.
# It never prints or exports saved credential values to the terminal.

. "$(dirname "$0")/require-bash.sh"

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
ENV_FILE="$ROOT/.env"
PROFILE_FILE="$ROOT/.env.model-profiles"
PROFILE_EXAMPLE="$ROOT/.env.model-profiles.example"

die() {
  printf '\033[31m%s\033[0m\n' "$1" >&2
  exit 1
}

info() {
  printf '\033[2m%s\033[0m\n' "$1"
}

ensure_files() {
  [ -f "$ENV_FILE" ] || cp "$ROOT/.env.example" "$ENV_FILE"
  if [ ! -f "$PROFILE_FILE" ]; then
    cp "$PROFILE_EXAMPLE" "$PROFILE_FILE"
    chmod 600 "$PROFILE_FILE"
  fi
}

# Values are stored as simple KEY=value lines. No profile is sourced as shell code.
value_from() {
  local file="$1" key="$2"
  { grep -E "^${key}=" "$file" || true; } | tail -1 | cut -d= -f2-
}

env_value() {
  value_from "$ENV_FILE" "$1"
}

profile_value() {
  value_from "$PROFILE_FILE" "$1"
}

set_in_file() {
  local file="$1" key="$2" value="$3" tmp
  tmp="$(mktemp "${file}.tmp.XXXXXX")"
  grep -vE "^${key}=" "$file" >"$tmp" || true
  printf '%s=%s\n' "$key" "$value" >>"$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$file"
}

set_env() {
  set_in_file "$ENV_FILE" "$1" "$2"
}

set_profile() {
  set_in_file "$PROFILE_FILE" "$1" "$2"
}

blank_active_connection() {
  local key
  for key in \
    CLAUDE_CODE_OAUTH_TOKEN \
    CHATGPT_AUTH_FILE CHATGPT_PLAN_HARNESS_URL CHATGPT_PLAN_HARNESS_TOKEN CHATGPT_PLAN_IMAGE \
    CLAUDE_PLAN_HARNESS_URL CLAUDE_PLAN_IMAGE \
    OPENAI_API_KEY OPENAI_BASE_URL OPENAI_CONTAINER_BASE_URL \
    BOT_MODEL BOT_PROVIDER \
    PICKED_HARNESS_IMAGE PICKED_HARNESS_URL PICKED_HARNESS_CONTAINER_URL PICKED_HARNESS_PORT; do
    set_env "$key" ""
  done
}

current_mode() {
  if [ -n "$(env_value CHATGPT_AUTH_FILE)" ]; then
    printf '%s' chatgpt
  elif [ -n "$(env_value CLAUDE_CODE_OAUTH_TOKEN)" ]; then
    printf '%s' claude
  elif [ -n "$(env_value OPENAI_API_KEY)" ] && [ "$(env_value OPENAI_BASE_URL)" = "$(profile_value OPENCODE_GO_BASE_URL)" ]; then
    printf '%s' opencode
  elif [ -n "$(env_value OPENAI_API_KEY)" ]; then
    printf '%s' openai-api
  else
    printf '%s' none
  fi
}

stop_plan_profiles() {
  # Profiles are omitted by the upstream stop script, so name them explicitly.
  docker compose --profile chatgpt-plan --profile claude-plan \
    stop agent-chatgpt-plan agent-claude-plan >/dev/null 2>&1 || true
  docker compose --profile chatgpt-plan --profile claude-plan \
    rm -f -s agent-chatgpt-plan agent-claude-plan >/dev/null 2>&1 || true
}

stop_stack() {
  bash "$ROOT/scripts/stop.sh"
  stop_plan_profiles
}

build_claude_image() {
  if ! docker image inspect openbot-agent-claude-sdk:latest >/dev/null 2>&1; then
    info "Building the local Claude Plan harness (one time)..."
    docker build --tag openbot-agent-claude-sdk:latest --file agent-claude-sdk/Dockerfile .
  fi
}

start_plan_harness() {
  case "$1" in
    chatgpt)
      docker compose --profile chatgpt-plan up -d --no-deps agent-chatgpt-plan
      ;;
    claude)
      build_claude_image
      docker compose --profile claude-plan up -d --no-deps agent-claude-plan
      ;;
    opencode|openai-api|none) ;;
    *) die "Unknown model mode: $1" ;;
  esac
}

start_stack() {
  # `scripts/start.sh` uses Bun directly. A desktop-terminal login normally has it in PATH,
  # but Make and other non-login shells need this small, explicit bootstrap.
  if ! command -v bun >/dev/null 2>&1; then
    if [ -x "${BUN_INSTALL:-$HOME/.bun}/bin/bun" ]; then
      export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
      export PATH="$BUN_INSTALL/bin:$PATH"
    else
      die "Bun was not found. Install it, then run this command again."
    fi
  fi

  # With no override this preserves upstream behavior: Docker tries to obtain current images and
  # falls back to local ones if it cannot. `make start-local` sets this to never for offline use.
  if [ -n "${OPENBOT_IMAGE_PULL_POLICY+x}" ]; then
    IMAGE_PULL_POLICY="$OPENBOT_IMAGE_PULL_POLICY" bash "$ROOT/scripts/start.sh"
  else
    bash "$ROOT/scripts/start.sh"
  fi
}

activate_chatgpt() {
  local auth_file="$ROOT/.langchain/chatgpt-auth.json"
  [ -f "$auth_file" ] || die "ChatGPT Plan session missing. Sign in again before selecting this mode."
  blank_active_connection
  set_env CHATGPT_AUTH_FILE /root/.langchain/chatgpt-auth.json
  set_env CHATGPT_PLAN_HARNESS_URL http://agent-chatgpt-plan:4206
  set_env CHATGPT_PLAN_IMAGE openbot-agent-langgraph-agui:latest
  set_env BOT_PROVIDER openai
}

activate_claude() {
  local token
  token="$(profile_value CLAUDE_CODE_OAUTH_TOKEN)"
  [ -n "$token" ] || die "No Claude token saved. Run: make save-claude-token"
  blank_active_connection
  set_env CLAUDE_CODE_OAUTH_TOKEN "$token"
  set_env CLAUDE_PLAN_HARNESS_URL http://agent-claude-plan:4212
  set_env CLAUDE_PLAN_IMAGE openbot-agent-claude-sdk:latest
  set_env BOT_PROVIDER anthropic
}

activate_opencode() {
  local key model base_url
  key="$(profile_value OPENCODE_GO_API_KEY)"
  model="$(profile_value OPENCODE_GO_MODEL)"
  base_url="$(profile_value OPENCODE_GO_BASE_URL)"
  [ -n "$key" ] || die "No OpenCode Go key saved. Run: make save-opencode-key"
  [ -n "$model" ] || die "Set OPENCODE_GO_MODEL in .env.model-profiles first."
  [ -n "$base_url" ] || die "Set OPENCODE_GO_BASE_URL in .env.model-profiles first."
  blank_active_connection
  set_env OPENAI_API_KEY "$key"
  set_env OPENAI_BASE_URL "$base_url"
  set_env BOT_MODEL "$model"
  set_env BOT_PROVIDER openai
}

activate_openai_api() {
  local key model base_url
  key="$(profile_value OPENAI_FALLBACK_API_KEY)"
  model="$(profile_value OPENAI_FALLBACK_MODEL)"
  base_url="$(profile_value OPENAI_FALLBACK_BASE_URL)"
  [ -n "$key" ] || die "No OpenAI API key saved. Run: make save-openai-key"
  blank_active_connection
  set_env OPENAI_API_KEY "$key"
  set_env OPENAI_BASE_URL "$base_url"
  set_env BOT_MODEL "$model"
  set_env BOT_PROVIDER openai
}

save_claude_token() {
  local token
  read -r -s -p "Paste the token from 'claude setup-token': " token
  printf '\n'
  [ -n "$token" ] || die "Nothing saved."
  set_profile CLAUDE_CODE_OAUTH_TOKEN "$token"
  printf '%s\n' "Claude token saved locally. Activate it with: make claude"
}

save_opencode_key() {
  local key model default_model
  read -r -s -p "Paste the OpenCode Go API key: " key
  printf '\n'
  [ -n "$key" ] || die "Nothing saved."
  default_model="$(profile_value OPENCODE_GO_MODEL)"
  read -r -p "OpenCode model [${default_model:-kimi-k3}]: " model
  set_profile OPENCODE_GO_API_KEY "$key"
  set_profile OPENCODE_GO_MODEL "${model:-${default_model:-kimi-k3}}"
  printf '%s\n' "OpenCode Go key saved locally. Activate it with: make opencode"
}

save_openai_key() {
  local key model default_model
  read -r -s -p "Paste the OpenAI API key: " key
  printf '\n'
  [ -n "$key" ] || die "Nothing saved."
  default_model="$(profile_value OPENAI_FALLBACK_MODEL)"
  read -r -p "OpenAI model (optional) [${default_model}]: " model
  set_profile OPENAI_FALLBACK_API_KEY "$key"
  set_profile OPENAI_FALLBACK_MODEL "${model:-$default_model}"
  printf '%s\n' "OpenAI API key saved locally. Activate it with: make openai-api"
}

status() {
  local mode
  mode="$(current_mode)"
  printf 'Project: %s\n' "$ROOT"
  printf 'Active model mode: %s\n' "$mode"
  printf 'ChatGPT Plan session: %s\n' "$( [ -f "$ROOT/.langchain/chatgpt-auth.json" ] && printf ready || printf missing )"
  printf 'Claude token saved: %s\n' "$( [ -n "$(profile_value CLAUDE_CODE_OAUTH_TOKEN)" ] && printf yes || printf no )"
  printf 'OpenCode Go key saved: %s\n' "$( [ -n "$(profile_value OPENCODE_GO_API_KEY)" ] && printf yes || printf no )"
  printf 'OpenAI API key saved: %s\n' "$( [ -n "$(profile_value OPENAI_FALLBACK_API_KEY)" ] && printf yes || printf no )"
  if curl -fsS --max-time 2 http://127.0.0.1:3001/health >/dev/null 2>&1; then
    printf 'Server: running (http://localhost:3010)\n'
  else
    printf 'Server: stopped\n'
  fi
  docker compose ps --all
}

usage() {
  cat <<'EOF'
Usage: bash scripts/use-model.sh <command>

  chatgpt            activate the saved ChatGPT Plan session and restart
  claude             activate the saved Claude Plan token and restart
  opencode           activate OpenCode Go and restart
  openai-api         activate the saved direct OpenAI API key and restart
  start              start the currently selected mode
  restart            restart the currently selected mode
  stop               stop OpenBot and both optional plan harnesses
  status             show redacted configuration and container status
  save-claude-token  save the output from `claude setup-token`
  save-opencode-key  save an OpenCode Go API key and model
  save-openai-key    save an OpenAI API key for the fallback mode
EOF
}

ensure_files
command="${1:-status}"
case "$command" in
  chatgpt|claude|opencode|openai-api)
    "activate_${command//-/_}"
    stop_stack
    start_plan_harness "$command"
    start_stack
    printf 'Selected model mode: %s\n' "$command"
    ;;
  start)
    mode="$(current_mode)"
    [ "$mode" != none ] || die "No model mode selected. Choose one with make chatgpt, make claude, make opencode, or make openai-api."
    stop_plan_profiles
    start_plan_harness "$mode"
    start_stack
    ;;
  restart)
    mode="$(current_mode)"
    [ "$mode" != none ] || die "No model mode selected."
    stop_stack
    start_plan_harness "$mode"
    start_stack
    ;;
  stop)
    stop_stack
    ;;
  status) status ;;
  save-claude-token) save_claude_token ;;
  save-opencode-key) save_opencode_key ;;
  save-openai-key) save_openai_key ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 1 ;;
esac

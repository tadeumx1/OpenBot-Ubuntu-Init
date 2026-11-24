# OpenBot Ubuntu Init

An unofficial, lightweight Ubuntu setup kit for [CopilotKit/OpenBot](https://github.com/CopilotKit/OpenBot).

This repository does **not** redistribute the OpenBot source code. It contains only the Ubuntu overlay developed for a local source checkout:

- A `Makefile` for starting, stopping, inspecting, and opening OpenBot.
- A browser-based Ubuntu application-menu launcher with database readiness checks.
- A model-mode switcher for ChatGPT Plan, Claude Plan, OpenCode Go, and a direct OpenAI API key.
- Templates and Git/Docker ignore rules that keep `.env`, OAuth sessions, and CopilotKit data out of commits and Docker build contexts.

It is an independent community setup, not an official CopilotKit release. This kit and OpenBot are MIT-licensed; see [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

## Quick start

Install Docker Engine with the Compose plugin and [Bun](https://bun.sh/) first. Clone the official OpenBot repository and this kit beside it:

```sh
git clone https://github.com/CopilotKit/OpenBot.git
git clone https://github.com/tadeumx1/OpenBot-Ubuntu-Init.git

cd OpenBot
bash ../OpenBot-Ubuntu-Init/install.sh .
```

The installer only adds or replaces its own overlay files. Before replacing a different local copy, it makes a timestamped backup at `.openbot-ubuntu-init-backup/`.

Continue with OpenBot's normal source setup:

```sh
cd OpenBot
cp .env.example .env
bun install
```

For managed CopilotKit Intelligence, add these non-secret endpoints to `.env`, then authenticate, select a project, and provision the Learning container:

```ini
INTELLIGENCE_API_URL=https://api.intelligence.copilotkit.ai
INTELLIGENCE_GATEWAY_WS_URL=wss://realtime.intelligence.copilotkit.ai
```

```sh
npx --yes copilotkit@latest login
npx --yes copilotkit@latest project select
bun scripts/setup-learning.ts
```

Choose and save a model connection, then start OpenBot:

```sh
make chatgpt                         # after supported ChatGPT Plan sign-in
# or: make save-claude-token && make claude
# or: make save-opencode-key && make opencode
# or: make save-openai-key && make openai-api

make start-local
make open
```

`make start` checks for current published images. `make start-local` reuses existing images and is useful when registry downloads are unavailable or unreliable.

## Ubuntu application launcher

The installer creates an **OpenBot** entry in the Ubuntu application menu. It starts the stack when needed, checks the API, frontend, and PostgreSQL, then opens the authorized local session in a Chrome app window.

Reinstall the menu entry after moving the checkout:

```sh
cd OpenBot
make install-launcher
```

The launcher log is `.logs/launcher.log`. For a clean local restart:

```sh
make restart-local
```

## Commands

```sh
make status          # redacted provider state and container status
make where           # checkout and log locations
make start           # start and check for current published images
make start-local     # start using local images only
make restart-local   # restart using local images only
make stop            # stop the app and Docker services
make logs            # follow Docker logs
make app-log         # follow the Vite frontend log
make open            # open a normal authorized browser tab
```

## Model modes

Credentials are saved locally in `.env.model-profiles`, which the overlay ignores in Git. The active connection alone is written into `.env`.

| Mode | Save | Activate | Notes |
| --- | --- | --- | --- |
| ChatGPT Plan | Supported local ChatGPT sign-in flow | `make chatgpt` | Uses a renewable local session store. |
| Claude Plan | `make save-claude-token` | `make claude` | Obtain the token with `claude setup-token`. |
| OpenCode Go | `make save-opencode-key` | `make opencode` | Uses an OpenAI-compatible API key, not OAuth. |
| OpenAI API | `make save-openai-key` | `make openai-api` | Direct API-key fallback. |

Only one subscription-plan login can be active at once: ChatGPT Plan or Claude Plan. Selecting one preserves saved local credentials for the others but restarts OpenBot with the selected mode.

## Security

The overlay adds these local-only paths to `.gitignore`:

- `.env` and `.env.*`
- `.langchain/` for ChatGPT OAuth session data
- `.copilotkit/` for local CopilotKit project data
- `.openbot-ubuntu-init-backup/`

It also adds `.langchain` and `.copilotkit` to `.dockerignore`, so OAuth renewal files and local project data are not copied into Docker build contexts. Never commit `.env`, API keys, OAuth tokens, or session stores to a public repository.

## Updating from upstream

Pull updates in the official OpenBot checkout as usual. Rerun this kit's installer to reapply the overlay, reviewing the timestamped backup if upstream changed one of the same files:

```sh
cd OpenBot
git pull
bash ../OpenBot-Ubuntu-Init/install.sh .
```

## GitHub Actions and releases

This kit does not contain GitHub Actions workflows and is intended as setup material, not a release distribution. Its repository has Actions disabled, so commits and tags do not run CI or release jobs.

.DEFAULT_GOAL := help

ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: help start start-local restart restart-local stop status where logs app-log open install-launcher \
	chatgpt claude opencode openai-api save-claude-token save-opencode-key save-openai-key

help:
	@printf '%s\n' 'OpenBot local controls'
	@printf '%s\n' '' \
	  '  make start          Start the selected mode; also checks for current Docker images.' \
	  '  make start-local    Start using local images only (best while Docker networking is unreliable).' \
	  '  make restart        Restart the selected mode.' \
	  '  make restart-local  Restart using local images only.' \
	  '  make stop           Stop OpenBot and optional plan harnesses.' \
	  '  make status         Show redacted provider state and containers.' \
	  '  make where          Show the project, logs, and running services.' \
	  '  make logs           Follow Docker logs.' \
	  '  make app-log        Follow the browser app log.' \
	  '  make open           Open the authorized browser session.' \
	  '  make install-launcher Install or refresh the Ubuntu app-menu launcher.' \
	  '' \
	  '  make chatgpt        Use the connected ChatGPT Plan session.' \
	  '  make save-claude-token && make claude' \
	  '  make save-opencode-key && make opencode' \
	  '  make save-openai-key && make openai-api'

start:
	@cd "$(ROOT)" && bash scripts/use-model.sh start

start-local:
	@cd "$(ROOT)" && OPENBOT_IMAGE_PULL_POLICY=never bash scripts/use-model.sh start

restart:
	@cd "$(ROOT)" && bash scripts/use-model.sh restart

restart-local:
	@cd "$(ROOT)" && OPENBOT_IMAGE_PULL_POLICY=never bash scripts/use-model.sh restart

stop:
	@cd "$(ROOT)" && bash scripts/use-model.sh stop

status:
	@cd "$(ROOT)" && bash scripts/use-model.sh status

where:
	@printf 'Project: %s\nApp log: %s.logs/app.log\n\n' "$(ROOT)" "$(ROOT)"
	@cd "$(ROOT)" && bash scripts/use-model.sh status

logs:
	@cd "$(ROOT)" && docker compose logs -f --tail=100

app-log:
	@cd "$(ROOT)" && tail -f .logs/app.log

open:
	@cd "$(ROOT)" && bash scripts/open-openbot.sh

install-launcher:
	@cd "$(ROOT)" && bash scripts/install-ubuntu-launcher.sh

chatgpt claude opencode openai-api:
	@cd "$(ROOT)" && bash scripts/use-model.sh $@

save-claude-token save-opencode-key save-openai-key:
	@cd "$(ROOT)" && bash scripts/use-model.sh $@

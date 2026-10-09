# Reusable CakePHP/multi-service application Makefile.
# Adapt service names, compose paths, and application commands before use.

CLI_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
CLI_ARG_TARGETS := $(sort $(subst :,\:,$(CLI_ARGS)))
$(eval .PHONY: $(CLI_ARG_TARGETS))
$(eval $(CLI_ARG_TARGETS):;@:)

APP_ENV_FILE ?= config/.env
COMPOSE_ENV_FILE ?=
COMPOSE_ENV ?= dev
COMPOSE_FILE ?= docker/compose/$(COMPOSE_ENV)/compose.yaml
PROD_COMPOSE_FILE ?= docker/compose/prod/compose.yaml
APP_SERVICE ?= app
LOGS_ARGS ?= --tail=200
CMD ?=

COMPOSE_ENV_ARGS := $(if $(strip $(COMPOSE_ENV_FILE)),--env-file "$(COMPOSE_ENV_FILE)",)
DEV_COMPOSE := docker/compose/dev.sh $(COMPOSE_ENV_ARGS) --app-env-file "$(APP_ENV_FILE)"
RUNTIME_COMPOSE := docker/compose/run.sh $(COMPOSE_ENV_ARGS) --app-env-file "$(APP_ENV_FILE)" -f "$(COMPOSE_FILE)"
DC := $(if $(filter dev,$(COMPOSE_ENV)),$(DEV_COMPOSE),$(RUNTIME_COMPOSE))
APP_EXEC := $(DC) exec --user www-data $(APP_SERVICE)

.PHONY: docker build up rebuild reload-env restart stop down remove pull push ps logs images config doctor \
	shell php composer cake console cache-clear migrate rollback cs-check cs-fix release change-release help

docker: ## Интерактивная оболочка Docker операций
	docker/compose/interactive.sh

build: ## Собрать application image текущего dev/stage окружения
	@test "$(COMPOSE_ENV)" != "prod" || { echo "Prod images собираются через make release." >&2; exit 1; }
	$(DC) build $(APP_SERVICE)

up: ## Запустить сервисы без неявной сборки
	$(DC) up -d --no-build $(CLI_ARGS)

rebuild: ## Явно пересобрать и пересоздать application service
	@test "$(COMPOSE_ENV)" = "dev" || { echo "rebuild разрешён только для dev." >&2; exit 1; }
	$(DC) build $(APP_SERVICE)
	$(DC) up -d --no-build --force-recreate $(APP_SERVICE)

reload-env: ## Пересоздать application service с актуальным env
	$(DC) up -d --no-build --force-recreate --no-deps $(APP_SERVICE)

restart: ## Перезапустить сервис без перечитывания env/image
	$(DC) restart $(or $(CLI_ARGS),$(APP_SERVICE))

stop: ## Остановить сервисы без удаления контейнеров и volumes
	$(DC) stop $(CLI_ARGS)

down: stop ## Безопасный alias: down только останавливает

remove: ## Удалить контейнеры/сеть без volumes
	$(DC) down $(CLI_ARGS)

pull: ## Явно скачать images
	$(DC) pull $(CLI_ARGS)

push: ## Явно отправить images
	$(DC) push $(CLI_ARGS)

ps: ## Показать контейнеры
	$(DC) ps --all

logs: ## Показать логи application service
	$(DC) logs $(LOGS_ARGS) $(or $(CLI_ARGS),$(APP_SERVICE))

images: ## Показать images итогового Compose config
	$(DC) config --images

config: ## Показать итоговый Compose config
	$(DC) config

doctor: ## Проверить Docker, env и Compose config
	COMPOSE_ENV="$(COMPOSE_ENV)" COMPOSE_ENV_FILE="$(COMPOSE_ENV_FILE)" APP_ENV_FILE="$(APP_ENV_FILE)" docker/compose/doctor.sh

shell: ## Открыть shell в application container
	$(APP_EXEC) sh

php: ## Выполнить PHP-команду: make php CMD='-v'
	$(APP_EXEC) php $(if $(strip $(CMD)),$(CMD),$(CLI_ARGS))

composer: ## Выполнить Composer-команду
	$(APP_EXEC) composer $(CLI_ARGS)

cake: ## Выполнить CakePHP command
	$(APP_EXEC) php bin/cake.php $(CLI_ARGS)

console: ## Выполнить application console command
	$(APP_EXEC) php bin/console $(CLI_ARGS)

cache-clear: ## Очистить application cache
	$(APP_EXEC) php bin/cake.php cache clear_all

migrate: ## Накатить одну migration; адаптируйте под проект
	$(APP_EXEC) php bin/cake.php migrations migrate

rollback: ## Откатить одну migration; адаптируйте под проект
	$(APP_EXEC) php bin/cake.php migrations rollback

cs-check: ## Проверить code style
	$(APP_EXEC) vendor/bin/php-cs-fixer fix --dry-run --diff --using-cache=no

cs-fix: ## Исправить code style
	$(APP_EXEC) vendor/bin/php-cs-fixer fix

release: ## Создать release tag/artifacts; нужны проектные release scripts
	sh docker/release/create-release.sh $(CLI_ARGS)

change-release: ## Переключить production на exact release images
	CHANGE_RELEASE_COMPOSE_FILE="$(PROD_COMPOSE_FILE)" APP_ENV_FILE="$(APP_ENV_FILE)" sh docker/release/change-release.sh $(CLI_ARGS)

help: ## Показать команды
	@awk 'BEGIN {FS = ":.*## "; printf "Доступные команды:\n"} /^[a-zA-Z0-9_.-]+:.*## / {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

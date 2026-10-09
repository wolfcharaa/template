# Spiral Docker Scripts Template

Этот каталог - переносимый эталон для Docker/Make/Lua-скриптов Spiral-проекта.
Он намеренно не подключен к runtime напрямую. В каталоге лежат переносимые
`compose/dev.sh`, `compose/run.sh` и `compose/doctor.sh`. Сначала шаблон
копируется в новый проект, затем адаптируются имена сервисов, registry prefix,
compose-файлы и список обязательных env.

## Цель

Шаблон должен помогать, а не становиться единственным способом запуска:

- `docker compose -f docker/compose/prod/compose.yaml up -d --no-build`
  должен оставаться рабочим без Make и Lua helpers;
- `Makefile` даёт короткие устойчивые команды для оператора;
- shell wrappers делают только shell-native работу: `exec`, compose вызовы,
  защита volumes, UID/GID, простая маршрутизация;
- Lua берёт на себя то, что плохо читается в shell: `.env` parsing,
  manifest/config validation, шаблоны, табличные сценарии и отчёты.

## Поддерживаемый минимум

- Lua 5.3.
- Только стандартные библиотеки Lua.
- Без LuaRocks и внешних модулей.
- Шаблон рассчитан на Debian 9+ и контейнеры, где можно поставить `lua5.3`.

Для Alpine PHP image:

```dockerfile
RUN apk add --no-cache lua5.3
```

Для Debian/Ubuntu image:

```dockerfile
RUN apt-get update \
    && apt-get install -y --no-install-recommends lua5.3 \
    && rm -rf /var/lib/apt/lists/*
```

## Рекомендуемая раскладка в проекте

```text
docker/
|-- compose/
|   |-- dev/compose.yaml
|   |-- stage/compose.yaml
|   |-- prod/compose.yaml
|   |-- dev.sh
|   |-- run.sh
|   |-- doctor.sh
|   |-- interactive.sh
|   |-- interactive.lua
|   `-- sanitize-legacy-compose.lua
|-- php/
|   |-- Dockerfile
|   |-- entrypoint.sh
|   `-- php.ini
|-- lua/
|   |-- project_data.lua
|   `-- spiral/
|       |-- cli.lua
|       |-- env.lua
|       `-- template.lua
|-- scripts/
|   |-- check-env.lua
|   |-- dump-plan.lua
|   |-- render-runtime-php-ini.lua
|   `-- render-template.lua
|-- release/
|   `-- manifest.lua
|-- templates/
|   |-- php-runtime.ini.tpl
|   `-- rr.yaml.tpl
`-- data/
```

`docker/templates/spiral/lua` при переносе обычно становится `docker/lua`, а
`docker/templates/spiral/scripts` становится `docker/scripts`.
`docker/templates/spiral/php` становится `docker/php`,
`docker/templates/spiral/compose` - `docker/compose`,
`docker/templates/spiral/release` - `docker/release`.

## Env Contract

Разделяйте два типа env:

- `APP_ENV_FILE`, по умолчанию `config/.env`: секреты, `DATABASE_URL`,
  endpoints внешних сервисов и feature flags приложения. Этот файл монтируется
  в контейнер как `app/.env` и читается самим Spiral-приложением.
- `COMPOSE_ENV_FILE`, по умолчанию пустой: редкие operator overrides для
  compose interpolation. Его не используют как основной `.env` приложения.

Compose должен хранить преимущественно конфигурацию контейнера и образа:

- `APP_ENV`, `APP_DEBUG`;
- RoadRunner/PHP runtime knobs;
- ports, volumes, profiles;
- memory/cpu limits;
- exact production image names.

## Makefile Contract

Смотрите `Makefile.fragment`. В новом проекте публичные цели лучше держать
короткими:

```makefile
up:
	docker/compose/dev.sh --app-env-file "$(APP_ENV_FILE)" up -d --no-build

release:
	sh docker/release/create-release.sh $(CLI_ARGS)

change-release:
	APP_ENV_FILE="$(APP_ENV_FILE)" sh docker/release/change-release.sh $(CLI_ARGS)
```

Makefile - удобная обертка, а не единственный источник правды. Для production
compose должен оставаться читаемым и запускаемым напрямую.

`docker/compose/interactive.sh` остаётся публичным entrypoint для `make docker`,
а `docker/compose/interactive.lua` хранит таблицу действий. Если меню растёт,
добавляйте новую запись в `actions`, а не новый большой `case` в shell.

## PHP Image Contract

`php/Dockerfile` собирает Spiral/RoadRunner image с `lua5.3`, копирует
`docker/lua` в `/usr/local/share/docker-lua`, а
`docker/scripts/render-runtime-php-ini.lua` - в
`/usr/local/bin/render-runtime-php-ini`.

`php/entrypoint.sh` должен оставаться тонким:

- настроить UID/GID и права runtime-директорий;
- вызвать `render-runtime-php-ini`;
- опционально выполнить composer install в dev;
- передать управление процессу через `exec`.

Сложную проверку runtime config держите в Lua renderer, а не в shell.

## Lua Helpers

`lua/spiral/env.lua`
: читает простые `.env` файлы, валидирует обязательные ключи, приводит bool,
  uint и size значения.

`lua/spiral/template.lua`
: рендерит шаблоны с плейсхолдерами `{{NAME}}`, пишет файл атомарно и не
  переписывает его, если содержимое не изменилось.

`lua/spiral/cli.lua`
: общий parser для маленьких Lua CLI-скриптов.

`lua/project_data.lua`
: декларативные списки prepared-data таблиц и наборы `all/raw/runtime`.
  Замените примерные таблицы на доменную модель проекта.

`compose/interactive.lua`
: компактный пример table-driven меню для Docker окружений. Shell wrapper
  остаётся в `compose/interactive.sh`.

`compose/sanitize-legacy-compose.lua`
: line-based sanitizer для fallback на старый `docker-compose` 1.x: добавляет
  `version: "2.4"` и убирает unsupported `name`, `platform`, `deploy`,
  `profiles`.

`release/manifest.lua`
: parser line-oriented `source-manifest.txt` для `change-release`: чтение
  key/value и проверка exact image list без `awk/grep`.

`scripts/check-env.lua`
: проверяет, что env-файл или process env содержит обязательные переменные.

`scripts/dump-plan.lua`
: печатает data dump plan из `lua/project_data.lua` в `text` или `shell`
  формате. Shell export/restore scripts могут `eval` shell-формат и не хранить
  списки таблиц внутри bash.

`scripts/render-template.lua`
: рендерит `.tpl` файлы через `.env`, process env и `--set KEY=VALUE`.

`scripts/render-runtime-php-ini.lua`
: рендерит `php-runtime.ini.tpl` с теми же defaults и проверками, которые
  нужны PHP image на старте.

## Примеры

Проверить application env:

```bash
lua5.3 docker/scripts/check-env.lua \
  --env-file config/.env \
  APP_SECRET DATABASE_URL
```

Сгенерировать runtime php ini:

```bash
lua5.3 docker/scripts/render-runtime-php-ini.lua \
  --env-file config/.env \
  --template docker/templates/php-runtime.ini.tpl \
  --out docker/data/generated/php-runtime.ini
```

Проверить dump plan:

```bash
lua5.3 docker/scripts/dump-plan.lua --set all --format text
lua5.3 docker/scripts/dump-plan.lua --set runtime --format shell
```

Проверить release manifest:

```bash
lua5.3 docker/release/manifest.lua \
  --file docker/data/release/v1.0.0/source-manifest.txt \
  --get release_version
```

Проверить legacy compose sanitizer:

```bash
lua5.3 docker/compose/sanitize-legacy-compose.lua \
  docker/compose/prod/docker-compose.yaml \
  /tmp/spiral-prod-legacy.yaml
```

## Что Переносить Первым

Хорошие первые кандидаты для Lua:

1. Генерация `php-runtime.ini` и `.rr.yaml` из `.tpl`.
2. Проверка `config/.env` перед `up/change-release`.
3. Интерактивное меню, если оно становится слишком большим для shell.
4. Manifest parsing/checking в release scripts.
5. Data manifest и списки таблиц в export/restore scripts.
6. Legacy compose sanitizer для серверов со старым `docker-compose`.

Не стоит начинать с entrypoint целиком: `exec`, пользователи, группы и сигналы
остаются естественнее в shell. Lua лучше вызывать из entrypoint точечно для
генерации файлов и сложной валидации.

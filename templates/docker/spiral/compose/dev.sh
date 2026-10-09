#!/bin/sh
set -eu

usage() {
    cat <<'USAGE'
Запуск dev Docker Compose для linux/amd64.

Использование:
  docker/compose/dev.sh [опции] <docker compose command>

Примеры:
  docker/compose/dev.sh ps
  docker/compose/dev.sh up -d
  docker/compose/dev.sh --data-tools run --rm spiral-data-tool
  docker/compose/dev.sh --no-database up -d

Опции:
  --local-database    Включить локальный PostgreSQL через profile local-database
  --no-database       Не включать локальный PostgreSQL
  --tools             Включить диагностические сервисы через profile tools
  --data-tools        Включить одноразовые сервисы через profile data-tools
  --env-file <file>   Compose/operator env-файл для interpolation
  --app-env-file <file>
                      Смонтировать application env-файл в app/.env
  -h, --help          Показать эту справку

Команда down в dev-обертке останавливает контейнеры без удаления.
Для явного docker compose down используй remove.
Команда up автоматически получает --no-build, если явно не передан --build.
USAGE
}

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
ROOT_DIR="$(CDPATH='' cd -- "${SCRIPT_DIR}/../.." && pwd)"
COMPOSE_ENV_FILE="${COMPOSE_ENV_FILE:-}"
APP_ENV_FILE="${APP_ENV_FILE:-}"
COMPOSE_PROFILES="${COMPOSE_PROFILES:-}"
LOCAL_DATABASE_MODE="auto"
INCLUDE_TOOLS=0
INCLUDE_DATA_TOOLS=0

append_profile() {
    profile="$1"

    if [ -z "${COMPOSE_PROFILES:-}" ]; then
        COMPOSE_PROFILES="${profile}"
        return
    fi

    case ",${COMPOSE_PROFILES}," in
        *",${profile},"*) ;;
        *) COMPOSE_PROFILES="${COMPOSE_PROFILES},${profile}" ;;
    esac
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --local-database)
            LOCAL_DATABASE_MODE="enabled"
            shift
            ;;
        --no-database)
            LOCAL_DATABASE_MODE="disabled"
            shift
            ;;
        --tools)
            INCLUDE_TOOLS=1
            shift
            ;;
        --data-tools)
            INCLUDE_DATA_TOOLS=1
            shift
            ;;
        --env-file)
            if [ "$#" -lt 2 ]; then
                echo "Ошибка: для --env-file нужно указать путь к файлу." >&2
                exit 1
            fi
            COMPOSE_ENV_FILE="$2"
            shift 2
            ;;
        --env-file=*)
            COMPOSE_ENV_FILE="${1#--env-file=}"
            shift
            ;;
        --app-env-file)
            if [ "$#" -lt 2 ]; then
                echo "Ошибка: для --app-env-file нужно указать путь к файлу." >&2
                exit 1
            fi
            APP_ENV_FILE="$2"
            shift 2
            ;;
        --app-env-file=*)
            APP_ENV_FILE="${1#--app-env-file=}"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done

if [ "$#" -eq 0 ]; then
    usage >&2
    exit 1
fi

has_build_flag() {
    for arg in "$@"; do
        case "${arg}" in
            --build|--no-build)
                return 0
                ;;
        esac
    done

    return 1
}

reject_volume_removal_args() {
    command="$1"
    shift

    case "${command}" in
        down|rm)
            for arg in "$@"; do
                case "${arg}" in
                    -v|--volumes)
                        echo "Ошибка: удаление Docker volumes запрещено. Постоянные данные удаляются только отдельной явной операцией." >&2
                        exit 1
                        ;;
                esac
            done
            ;;
    esac
}

is_uint() {
    case "${1:-}" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

cd "${ROOT_DIR}"

resolve_path() {
    case "$1" in
        /*) printf '%s\n' "$1" ;;
        *) printf '%s/%s\n' "${ROOT_DIR}" "$1" ;;
    esac
}

APP_ENV_FILE="${APP_ENV_FILE:-config/.env}"
APP_ENV_FILE="$(resolve_path "${APP_ENV_FILE}")"

if [ ! -f "${APP_ENV_FILE}" ]; then
    echo "Ошибка: application env-файл не найден: ${APP_ENV_FILE}" >&2
    exit 1
fi

HOST_RUNTIME_UID="$(id -u)"
HOST_RUNTIME_GID="$(id -g)"

if [ "${HOST_RUNTIME_UID}" = "0" ]; then
    echo "Ошибка: dev-контур нельзя запускать от root или через sudo." >&2
    exit 1
fi

APP_RUNTIME_UID="${APP_RUNTIME_UID:-${HOST_RUNTIME_UID}}"
APP_RUNTIME_GID="${APP_RUNTIME_GID:-${HOST_RUNTIME_GID}}"
APP_RUNTIME_USER_NAME="${APP_RUNTIME_USER_NAME:-$(id -un 2>/dev/null || printf 'app-%s' "${APP_RUNTIME_UID}")}"

if ! is_uint "${APP_RUNTIME_UID}" || [ "${APP_RUNTIME_UID}" = "0" ]; then
    echo "Ошибка: APP_RUNTIME_UID должен быть ненулевым числовым UID; получено '${APP_RUNTIME_UID}'." >&2
    exit 1
fi

if ! is_uint "${APP_RUNTIME_GID}" || [ "${APP_RUNTIME_GID}" = "0" ]; then
    echo "Ошибка: APP_RUNTIME_GID должен быть ненулевым числовым GID; получено '${APP_RUNTIME_GID}'." >&2
    exit 1
fi

case "${APP_RUNTIME_USER_NAME}" in
    ''|*[!A-Za-z0-9_.-]*)
        echo "Ошибка: APP_RUNTIME_USER_NAME может содержать только буквы, цифры, точку, дефис и подчеркивание; получено '${APP_RUNTIME_USER_NAME}'." >&2
        exit 1
        ;;
esac

case "${LOCAL_DATABASE_MODE}" in
    enabled)
        append_profile local-database
        ;;
    disabled)
        COMPOSE_PROFILES="$(printf '%s' "${COMPOSE_PROFILES:-}" | sed 's/local-database//; s/,,*/,/g; s/^,//; s/,$//')"
        ;;
    auto)
        if [ -z "${COMPOSE_PROFILES:-}" ]; then
            append_profile local-database
        fi
        ;;
esac

if [ "${INCLUDE_TOOLS}" = "1" ]; then
    append_profile tools
fi

if [ "${INCLUDE_DATA_TOOLS}" = "1" ]; then
    append_profile data-tools
fi

export APP_RUNTIME_UID
export APP_RUNTIME_GID
export APP_RUNTIME_USER_NAME
export APP_ENV_FILE
APP_RUNTIME_CONFIGURED=1
export APP_RUNTIME_CONFIGURED
export COMPOSE_PROFILES

echo "Платформа Docker: linux/amd64; profiles=${COMPOSE_PROFILES:-none}" >&2

case "${1:-}" in
    down)
        shift
        set -- stop "$@"
        ;;
    remove)
        shift
        set -- down "$@"
        ;;
    up)
        if ! has_build_flag "$@"; then
            shift
            set -- up --no-build "$@"
        fi
        ;;
esac

reject_volume_removal_args "$@"

if [ -n "${COMPOSE_ENV_FILE}" ]; then
    exec docker compose --env-file "${COMPOSE_ENV_FILE}" -f docker/compose/dev/compose.yaml "$@"
fi

exec docker compose -f docker/compose/dev/compose.yaml "$@"

#!/bin/sh
set -eu

usage() {
    cat <<'USAGE'
Запуск Docker Compose для stage/prod.

Использование:
  docker/compose/run.sh [опции] <compose command>

Опции:
  --env-file <file>       Compose/operator env-файл для interpolation
  --app-env-file <file>   Application env-файл для mount в app/.env
  -f, --file <file>       Compose-файл. Можно указывать несколько раз
  -p, --project-name <n>  Имя compose-проекта, по умолчанию spiral-app
  --legacy                Принудительно использовать legacy docker-compose
  -h, --help              Показать справку

Команда up автоматически получает --no-build, если явно не передан --build.
USAGE
}

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
ROOT_DIR="$(CDPATH='' cd -- "${SCRIPT_DIR}/../.." && pwd)"
COMPOSE_ENV_FILE="${COMPOSE_ENV_FILE:-}"
APP_ENV_FILE="${APP_ENV_FILE:-}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-spiral-app}"
COMPOSE_FILES=""
FORCE_LEGACY="${COMPOSE_LEGACY:-0}"

while [ "$#" -gt 0 ]; do
    case "$1" in
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
        -f|--file)
            if [ "$#" -lt 2 ]; then
                echo "Ошибка: для $1 нужно указать compose-файл." >&2
                exit 1
            fi
            COMPOSE_FILES="${COMPOSE_FILES} $2"
            shift 2
            ;;
        --file=*)
            COMPOSE_FILES="${COMPOSE_FILES} ${1#--file=}"
            shift
            ;;
        -p|--project-name)
            if [ "$#" -lt 2 ]; then
                echo "Ошибка: для $1 нужно указать имя проекта." >&2
                exit 1
            fi
            COMPOSE_PROJECT_NAME="$2"
            shift 2
            ;;
        --project-name=*)
            COMPOSE_PROJECT_NAME="${1#--project-name=}"
            shift
            ;;
        --legacy)
            FORCE_LEGACY=1
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
        -*)
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

if [ "${1:-}" = "up" ] && ! has_build_flag "$@"; then
    shift
    set -- up --no-build "$@"
fi

cd "${ROOT_DIR}"

if [ -z "${COMPOSE_FILES}" ]; then
    COMPOSE_FILES="docker/compose/prod/compose.yaml"
fi

for file in ${COMPOSE_EXTRA_FILES:-}; do
    COMPOSE_FILES="${COMPOSE_FILES} ${file}"
done

if [ -z "${APP_ENV_FILE}" ]; then
    APP_ENV_FILE="config/.env"
fi

if [ -n "${COMPOSE_ENV_FILE}" ]; then
    case "${COMPOSE_ENV_FILE}" in
        /*) ;;
        *) COMPOSE_ENV_FILE="${ROOT_DIR}/${COMPOSE_ENV_FILE}" ;;
    esac
fi

case "${APP_ENV_FILE}" in
    /*) ;;
    *) APP_ENV_FILE="${ROOT_DIR}/${APP_ENV_FILE}" ;;
esac

if [ ! -f "${APP_ENV_FILE}" ]; then
    echo "Ошибка: application env-файл не найден: ${APP_ENV_FILE}" >&2
    exit 1
fi

export APP_ENV_FILE

env_value() {
    name="$1"
    file="$2"

    if [ ! -f "${file}" ]; then
        return
    fi

    sed -n "s/^${name}=//p" "${file}" | tail -n 1 | sed "s/^['\"]//; s/['\"]$//"
}

ensure_compose_defaults() {
    case " ${COMPOSE_FILES} " in
        *"docker/compose/prod/compose.yaml"*) compose_env="prod" ;;
        *"docker/compose/stage/compose.yaml"*) compose_env="stage" ;;
        *) compose_env="dev" ;;
    esac

    RELEASE_VERSION="${RELEASE_VERSION:-$(env_value RELEASE_VERSION "${COMPOSE_ENV_FILE}")}"
    if [ -z "${RELEASE_VERSION}" ]; then
        case "${compose_env}" in
            stage) RELEASE_VERSION="stage" ;;
            prod) RELEASE_VERSION="prod" ;;
        esac
    fi

    RELEASE_IMAGE_TAG="${RELEASE_IMAGE_TAG:-$(env_value RELEASE_IMAGE_TAG "${COMPOSE_ENV_FILE}")}"
    if [ -z "${RELEASE_IMAGE_TAG}" ] && [ -n "${RELEASE_VERSION}" ]; then
        RELEASE_IMAGE_TAG="${RELEASE_VERSION}-linux-amd64"
    fi

    LOCAL_POSTGRES_PORT="${LOCAL_POSTGRES_PORT:-$(env_value LOCAL_POSTGRES_PORT "${COMPOSE_ENV_FILE}")}"
    LOCAL_POSTGRES_PORT="${LOCAL_POSTGRES_PORT:-5435}"

    export RELEASE_VERSION
    export RELEASE_IMAGE_TAG
    export LOCAL_POSTGRES_PORT
}

reject_volume_removal_args "$@"

require_lua() {
    if ! command -v lua5.3 >/dev/null 2>&1; then
        echo "Ошибка: legacy Docker Compose fallback требует lua5.3 для подготовки compose-файла." >&2
        exit 1
    fi
}

compose_supports_env_file() {
    docker compose --help 2>/dev/null | grep -q -- '--env-file'
}

is_legacy_compose() {
    if [ "${FORCE_LEGACY}" = "1" ]; then
        return 0
    fi

    if ! compose_supports_env_file; then
        return 0
    fi

    return 1
}

load_env_file() {
    if [ -z "${COMPOSE_ENV_FILE}" ]; then
        return
    fi

    if [ ! -f "${COMPOSE_ENV_FILE}" ]; then
        echo "Ошибка: env-файл не найден: ${COMPOSE_ENV_FILE}" >&2
        exit 1
    fi

    set -a
    # shellcheck disable=SC1090
    . "${COMPOSE_ENV_FILE}"
    set +a
}

sanitize_compose_file() {
    src="$1"
    dst="$2"

    require_lua
    lua5.3 docker/compose/sanitize-legacy-compose.lua "${src}" "${dst}"
}

run_modern() {
    ensure_compose_defaults

    compose_file_args=""
    for file in ${COMPOSE_FILES}; do
        compose_file_args="${compose_file_args} -f ${file}"
    done

    if [ -n "${COMPOSE_ENV_FILE}" ]; then
        # compose_file_args intentionally expands as docker compose -f pairs.
        # shellcheck disable=SC2086
        exec docker compose --env-file "${COMPOSE_ENV_FILE}" -p "${COMPOSE_PROJECT_NAME}" ${compose_file_args} "$@"
    fi

    # compose_file_args intentionally expands as docker compose -f pairs.
    # shellcheck disable=SC2086
    exec docker compose -p "${COMPOSE_PROJECT_NAME}" ${compose_file_args} "$@"
}

run_legacy() {
    load_env_file
    ensure_compose_defaults

    legacy_tmp_files=""
    cleanup() {
        if [ -z "${legacy_tmp_files}" ]; then
            return
        fi

        # legacy_tmp_files intentionally expands as a list of generated file paths.
        # shellcheck disable=SC2086
        rm -f ${legacy_tmp_files}
    }
    trap cleanup EXIT INT TERM

    compose_file_args=""
    index=0
    for file in ${COMPOSE_FILES}; do
        index=$((index + 1))
        case "${file}" in
            /*) src="${file}" ;;
            *) src="${ROOT_DIR}/${file}" ;;
        esac

        if [ ! -f "${src}" ]; then
            echo "Ошибка: compose-файл не найден: ${src}" >&2
            exit 1
        fi

        dst="$(mktemp "$(dirname "${src}")/.spiral-app-compose-${index}.XXXXXX")"
        legacy_tmp_files="${legacy_tmp_files} ${dst}"
        sanitize_compose_file "${src}" "${dst}"
        compose_file_args="${compose_file_args} -f ${dst}"
    done

    echo "Legacy Docker Compose: project=${COMPOSE_PROJECT_NAME}, platform=linux/amd64" >&2

    set +e
    if command -v docker-compose >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        docker-compose -p "${COMPOSE_PROJECT_NAME}" ${compose_file_args} "$@"
    else
        # shellcheck disable=SC2086
        docker compose -p "${COMPOSE_PROJECT_NAME}" ${compose_file_args} "$@"
    fi
    status="$?"
    set -e

    cleanup
    trap - EXIT INT TERM
    exit "${status}"
}

if is_legacy_compose; then
    run_legacy "$@"
else
    run_modern "$@"
fi

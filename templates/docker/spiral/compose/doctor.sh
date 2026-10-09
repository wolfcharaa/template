#!/bin/sh
set -eu

COMPOSE_ENV="${COMPOSE_ENV:-dev}"
COMPOSE_ENV_FILE="${COMPOSE_ENV_FILE:-}"
APP_ENV_FILE="${APP_ENV_FILE:-config/.env}"
COMPOSE_EXTRA_FILES="${COMPOSE_EXTRA_FILES:-}"

echo "Docker:"
docker --version

echo "Docker Compose:"
docker compose version

echo "Compose env: ${COMPOSE_ENV}"
echo "Compose env file: ${COMPOSE_ENV_FILE:-<none>}"
echo "App env file: ${APP_ENV_FILE}"

if [ -n "${COMPOSE_ENV_FILE}" ] && [ ! -f "${COMPOSE_ENV_FILE}" ]; then
    echo "Env file is missing: ${COMPOSE_ENV_FILE}" >&2
    exit 1
fi

if [ ! -f "${APP_ENV_FILE}" ]; then
    echo "App env file is missing: ${APP_ENV_FILE}" >&2
    exit 1
fi

if [ "${COMPOSE_ENV}" = "dev" ]; then
    COMPOSE_PROFILES="${COMPOSE_PROFILES:-local-database}" COMPOSE_ENV_FILE="${COMPOSE_ENV_FILE}" APP_ENV_FILE="${APP_ENV_FILE}" COMPOSE_EXTRA_FILES="${COMPOSE_EXTRA_FILES}" docker/compose/dev.sh config >/dev/null
else
    compose_file="docker/compose/${COMPOSE_ENV}/compose.yaml"
    args="-f ${compose_file}"
    for file in ${COMPOSE_EXTRA_FILES}; do
        args="${args} -f ${file}"
    done
    # args intentionally expands as docker compose -f pairs.
    # shellcheck disable=SC2086
    if [ -n "${COMPOSE_ENV_FILE}" ]; then
        docker/compose/run.sh --env-file "${COMPOSE_ENV_FILE}" --app-env-file "${APP_ENV_FILE}" ${args} config >/dev/null
    else
        docker/compose/run.sh --app-env-file "${APP_ENV_FILE}" ${args} config >/dev/null
    fi
fi

echo "Compose config: ok"

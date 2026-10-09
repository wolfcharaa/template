#!/bin/bash
set -euo pipefail

APP_DIR="${APP_DIR:-/var/www/html/app}"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "${APP_DIR}")}"
APP_RUNTIME_USER="www-data"
APP_RUNTIME_GROUP="www-data"

cd "${APP_DIR}"

is_uint() {
    case "${1:-}" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

user_by_uid() {
    getent passwd "$1" | cut -d: -f1 || true
}

group_by_gid() {
    getent group "$1" | cut -d: -f1 || true
}

project_find() {
    find "${PROJECT_DIR}" \
        \( -path "${PROJECT_DIR}/.git" -o -path "${PROJECT_DIR}/.git/*" -o -path "${PROJECT_DIR}/docker/data" -o -path "${PROJECT_DIR}/docker/data/*" \) -prune \
        -o "$@"
}

run_command_as_runtime_user() {
    if [ "$(id -u)" = "0" ] && [ "${APP_RUNTIME_USER}" != "root" ]; then
        su-exec "${APP_RUNTIME_USER}:${APP_RUNTIME_GROUP}" "$@"
        return
    fi

    "$@"
}

configure_www_data_identity() {
    target_uid="${APP_RUNTIME_UID:-}"
    target_gid="${APP_RUNTIME_GID:-}"

    if [ -z "${target_uid}" ] && [ -z "${target_gid}" ]; then
        if [ "$(id -u)" = "0" ]; then
            APP_RUNTIME_USER="www-data"
            APP_RUNTIME_GROUP="www-data"
        else
            APP_RUNTIME_USER="$(id -un)"
            APP_RUNTIME_GROUP="$(id -gn)"
        fi

        if [ "$(id -u "${APP_RUNTIME_USER}")" = "0" ]; then
            echo "ERROR: the fixed PHP application user must not be root." >&2
            exit 78
        fi

        return
    fi

    if ! is_uint "${target_uid}" || [ "${target_uid}" = "0" ]; then
        echo "ERROR: APP_RUNTIME_UID must be a non-zero numeric UID; got '${target_uid}'." >&2
        exit 78
    fi

    if ! is_uint "${target_gid}" || [ "${target_gid}" = "0" ]; then
        echo "ERROR: APP_RUNTIME_GID must be a non-zero numeric GID; got '${target_gid}'." >&2
        exit 78
    fi

    if [ "$(id -u)" != "0" ]; then
        if [ "$(id -u)" != "${target_uid}" ] || [ "$(id -g)" != "${target_gid}" ]; then
            echo "ERROR: container user $(id -u):$(id -g) does not match APP_RUNTIME_UID:GID ${target_uid}:${target_gid}." >&2
            exit 78
        fi

        APP_RUNTIME_USER="$(id -un)"
        APP_RUNTIME_GROUP="$(id -gn)"
        return
    fi

    existing_group="$(group_by_gid "${target_gid}")"
    current_www_gid="$(getent group www-data | cut -d: -f3)"

    if [ -z "${existing_group}" ] || [ "${existing_group}" = "www-data" ]; then
        if [ "${current_www_gid}" != "${target_gid}" ]; then
            groupmod -g "${target_gid}" www-data
        fi
        APP_RUNTIME_GROUP="www-data"
    else
        APP_RUNTIME_GROUP="${existing_group}"
        usermod -g "${existing_group}" www-data
    fi

    existing_user="$(user_by_uid "${target_uid}")"
    current_www_uid="$(id -u www-data)"

    if [ -n "${existing_user}" ] && [ "${existing_user}" != "www-data" ]; then
        echo "ERROR: APP_RUNTIME_UID ${target_uid} already belongs to '${existing_user}' in the PHP image." >&2
        exit 78
    fi

    if [ "${current_www_uid}" != "${target_uid}" ]; then
        usermod -u "${target_uid}" -d "${APP_DIR}" www-data
    fi

    usermod -g "${APP_RUNTIME_GROUP}" www-data
    APP_RUNTIME_USER="www-data"

    if [ "$(id -u "${APP_RUNTIME_USER}")" != "${target_uid}" ] \
        || [ "$(id -g "${APP_RUNTIME_USER}")" != "${target_gid}" ]; then
        echo "ERROR: failed to configure PHP runtime identity ${target_uid}:${target_gid}." >&2
        exit 78
    fi
}

write_runtime_php_ini() {
    render-runtime-php-ini
}

ensure_runtime_dirs() {
    mkdir -p \
        runtime/cache \
        runtime/logs \
        runtime/session \
        runtime/snapshots \
        runtime/tmp \
        runtime/rr \
        /tmp/composer
}

fix_permissions() {
    configure_www_data_identity
    ensure_runtime_dirs

    if [ "$(id -u)" = "0" ]; then
        chown -R "${APP_RUNTIME_USER}:${APP_RUNTIME_GROUP}" runtime /tmp/composer
        chmod -R ug+rwX runtime /tmp/composer
        find runtime /tmp/composer -type d -exec chmod g+s {} +
    else
        chmod -R u+rwX,g+rwX runtime /tmp/composer 2>/dev/null || true
    fi
}

fix_permissions_all() {
    configure_www_data_identity
    fix_permissions

    if [ "$(id -u)" = "0" ]; then
        project_find -exec chown "${APP_RUNTIME_USER}:${APP_RUNTIME_GROUP}" {} +
        project_find -type d -exec chmod 2775 {} +
        project_find -type f -exec chmod ug+rw {} +
        project_find -type f -perm /111 -exec chmod ug+x {} +
    else
        project_find -type d -exec chmod 2775 {} + 2>/dev/null || true
        project_find -type f -exec chmod ug+rw {} + 2>/dev/null || true
        project_find -type f -perm /111 -exec chmod ug+x {} + 2>/dev/null || true
    fi
}

case "${1:-}" in
    fix-permissions)
        fix_permissions
        exit 0
        ;;
    fix-permissions-all)
        fix_permissions_all
        exit 0
        ;;
esac

configure_www_data_identity
write_runtime_php_ini
fix_permissions

if [ "${APP_SKIP_COMPOSER_INSTALL:-0}" != "1" ] && [ "${COMPOSER_INSTALL_ON_START:-1}" = "1" ] && [ -f composer.json ]; then
    echo "Running composer install..."
    # COMPOSER_INSTALL_FLAGS deliberately allows word splitting for flags from env.
    # shellcheck disable=SC2086
    run_command_as_runtime_user env COMPOSER_HOME=/tmp/composer composer install \
        ${COMPOSER_INSTALL_FLAGS:-} \
        --no-interaction \
        --prefer-dist \
        --no-progress
fi

if [ "$(id -u)" = "0" ] && [ "${APP_RUN_AS_ROOT:-0}" != "1" ]; then
    exec su-exec "${APP_RUNTIME_USER}:${APP_RUNTIME_GROUP}" "$@"
fi

exec "$@"

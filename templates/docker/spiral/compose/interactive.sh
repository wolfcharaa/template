#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"

if ! command -v lua5.3 >/dev/null 2>&1; then
    echo "Ошибка: для интерактивной оболочки нужен lua5.3." >&2
    echo "Установите lua5.3 или используйте docker/compose/*.sh напрямую." >&2
    exit 1
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ "$#" -gt 0 ]; then
    exec lua5.3 "${SCRIPT_DIR}/interactive.lua" "$@"
fi

if [ ! -t 0 ]; then
    echo "Ошибка: интерактивная оболочка требует TTY." >&2
    echo "Для автоматизации используйте docker/compose/*.sh напрямую." >&2
    exit 1
fi

exec lua5.3 "${SCRIPT_DIR}/interactive.lua" "$@"

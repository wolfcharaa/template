#!/usr/bin/env lua5.3

local script_dir = (arg and arg[0] or ""):match("^(.*)/[^/]*$") or "."
local root_dir = script_dir:gsub("/?docker/compose$", "")
if root_dir == "" then
    root_dir = "."
end
package.path = script_dir .. "/../lua/?.lua;" .. script_dir .. "/../lua/?/init.lua;" ..
    root_dir .. "/docker/lua/?.lua;" .. root_dir .. "/docker/lua/?/init.lua;" .. package.path

local env = require("spiral.env")

local project_name = "spiral-app"
local registry_prefix_default = "registry.example/team/spiral-app"
local app_service = "spiral-app"
local worker_service = "spiral-worker"
local database_service = "spiral-database"

local state = {
    compose_env_name = nil,
    compose_env_file = "",
    app_env_file = "config/.env",
    docker_image_prefix = registry_prefix_default,
    release_image_tag = "",
    compose_profiles = "",
    dev_database_arg = "",
}

local function usage()
    io.write([[
Интерактивная оболочка Docker окружений Spiral-проекта.

Использование:
  make docker
  docker/compose/interactive.sh

Shell wrapper остаётся публичным entrypoint; меню и таблица действий живут здесь.
]])
end

local function fail(message, code)
    io.stderr:write(message .. "\n")
    os.exit(code or 1)
end

local function shell_quote(value)
    value = tostring(value or "")
    return "'" .. value:gsub("'", [["'"']]) .. "'"
end

local function command_status(result, exit_type, code)
    if result == true then
        return 0
    end
    if type(result) == "number" then
        return result
    end
    if exit_type == "exit" and type(code) == "number" then
        return code
    end
    return 1
end

local function run_process(argv, extra_env)
    local parts = { "cd " .. shell_quote(root_dir) }
    local command = {}

    for name, value in pairs(extra_env or {}) do
        table.insert(command, name .. "=" .. shell_quote(value))
    end
    for _, value in ipairs(argv) do
        table.insert(command, shell_quote(value))
    end

    table.insert(parts, table.concat(command, " "))
    return command_status(os.execute(table.concat(parts, " && ")))
end

local function split_words(input)
    local words = {}
    for word in tostring(input or ""):gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

local function append_all(target, source)
    for _, value in ipairs(source) do
        table.insert(target, value)
    end
end

local function ask(prompt, default)
    io.stderr:write(string.format("%s [%s]: ", prompt, default))
    local answer = io.read("*l")
    if answer == nil then
        io.stderr:write("\n")
        os.exit(0)
    end
    if answer == "" then
        answer = default
    end
    return answer
end

local function ask_optional(prompt)
    io.stderr:write(prompt .. ": ")
    local answer = io.read("*l")
    if answer == nil then
        io.stderr:write("\n")
        os.exit(0)
    end
    return answer
end

local function is_yes(value)
    return value == "y" or value == "Y" or value == "yes" or value == "YES"
        or value == "д" or value == "Д" or value == "да" or value == "Да" or value == "ДА"
end

local function env_value(name, path)
    if path == nil or path == "" then
        return nil
    end

    local ok, values = pcall(env.load_file, path, { optional = true })
    if not ok then
        return nil
    end

    return values[name]
end

local function append_profile(profile)
    if state.compose_profiles == "" then
        state.compose_profiles = profile
        return
    end
    if not ("," .. state.compose_profiles .. ","):find("," .. profile .. ",", 1, true) then
        state.compose_profiles = state.compose_profiles .. "," .. profile
    end
end

local function compose_runtime_env()
    return {
        COMPOSE_PROFILES = state.compose_profiles,
        DOCKER_IMAGE_PREFIX = state.docker_image_prefix,
        RELEASE_IMAGE_TAG = state.release_image_tag,
    }
end

local function compose_env_args()
    if state.compose_env_file ~= "" then
        return { "--env-file", state.compose_env_file }
    end
    return {}
end

local function map_service_token(token)
    local aliases = {
        app = app_service,
        php = app_service,
        worker = worker_service,
        db = database_service,
        database = database_service,
        postgres = database_service,
    }
    return aliases[token] or token
end

local function read_services(input, default)
    if input == "" then
        input = default
    end

    local services = {}
    for _, token in ipairs(split_words(input)) do
        if token == "all" then
            table.insert(services, app_service)
            table.insert(services, worker_service)
            table.insert(services, database_service)
        else
            table.insert(services, map_service_token(token))
        end
    end
    return services
end

local function run_compose_words(words)
    local argv = {}
    if state.compose_env_name == "dev" then
        argv = { "docker/compose/dev.sh" }
        append_all(argv, compose_env_args())
        if state.dev_database_arg ~= "" then
            table.insert(argv, state.dev_database_arg)
        end
        append_all(argv, { "--app-env-file", state.app_env_file })
        append_all(argv, words)
        return run_process(argv, compose_runtime_env())
    end

    argv = { "docker/compose/run.sh" }
    append_all(argv, compose_env_args())
    append_all(argv, { "--app-env-file", state.app_env_file, "-f", "docker/compose/" .. state.compose_env_name .. "/compose.yaml" })
    append_all(argv, words)
    return run_process(argv, compose_runtime_env())
end

local function run_status()
    return run_compose_words({ "ps", "--all" })
end

local function run_up()
    local services = ask_optional("Сервисы для запуска; Enter = все сервисы текущего окружения/profiles")
    local argv = { "up", "-d", "--no-build" }
    if services ~= "" then
        append_all(argv, read_services(services, ""))
    end
    return run_compose_words(argv)
end

local function run_reload_env()
    return run_compose_words({ "up", "-d", "--no-build", "--force-recreate", "--no-deps", app_service })
end

local function run_logs()
    local services = ask("Сервисы для просмотра логов", "app")
    local tail_lines = ask("Сколько последних строк показать", "200")
    local argv = { "logs", "--tail=" .. tail_lines }
    append_all(argv, read_services(services, "app"))
    return run_compose_words(argv)
end

local function run_shell()
    return run_compose_words({ "exec", "--user", "www-data", app_service, "sh" })
end

local function run_app_command()
    local command = ask("Команда app.php", "app:about")
    local argv = { "exec", "--user", "www-data", app_service, "php", "app.php" }
    append_all(argv, split_words(command))
    return run_compose_words(argv)
end

local function run_migrate()
    return run_compose_words({ "exec", "--user", "www-data", app_service, "php", "app.php", "migrate:up", "--no-interaction" })
end

local function run_custom_compose()
    local command = ask("Своя docker compose команда", "config")
    local argv = split_words(command)
    if #argv == 0 then
        io.stderr:write("Пустая compose-команда.\n")
        return 1
    end
    return run_compose_words(argv)
end

local function select_context()
    io.stderr:write([[
Окружение:
  1) dev
  2) stage
  3) prod
]])
    local env_choice = ask("Выберите окружение", "1")
    if env_choice == "1" or env_choice == "dev" then
        state.compose_env_name = "dev"
    elseif env_choice == "2" or env_choice == "stage" then
        state.compose_env_name = "stage"
    elseif env_choice == "3" or env_choice == "prod" then
        state.compose_env_name = "prod"
    else
        fail("Ошибка: неизвестное окружение '" .. env_choice .. "'.")
    end

    state.compose_env_file = ask_optional("Compose/operator env-файл; Enter = не использовать")
    state.app_env_file = ask("Application env-файл для app/.env", "config/.env")
    state.docker_image_prefix = ask("DOCKER_IMAGE_PREFIX", os.getenv("DOCKER_IMAGE_PREFIX") or env_value("DOCKER_IMAGE_PREFIX", state.compose_env_file) or registry_prefix_default)
    state.release_image_tag = ask("RELEASE_IMAGE_TAG", os.getenv("RELEASE_IMAGE_TAG") or env_value("RELEASE_IMAGE_TAG", state.compose_env_file) or state.compose_env_name .. "-linux-amd64")

    if state.compose_env_name == "dev" then
        if is_yes(ask("Локальная PostgreSQL", "y")) then
            append_profile("local-database")
            state.dev_database_arg = "--local-database"
        else
            state.dev_database_arg = "--no-database"
        end
    elseif state.compose_env_name == "prod" and is_yes(ask("Локальная PostgreSQL", "n")) then
        append_profile("database")
    end

    io.stderr:write(string.format([[

Контекст:
  project:          %s
  окружение:        %s
  compose env-файл: %s
  app env-файл:     %s
  образ app:        %s/php:%s
  compose profiles: %s
]], project_name, state.compose_env_name, state.compose_env_file ~= "" and state.compose_env_file or "<none>",
        state.app_env_file, state.docker_image_prefix, state.release_image_tag,
        state.compose_profiles ~= "" and state.compose_profiles or "<none>"))
end

local actions = {
    { "1", "Контейнеры: статус", { "status", "ps" }, run_status },
    { "2", "Контейнеры: запустить без сборки", { "up" }, run_up },
    { "3", "Контейнеры: пересоздать app с новым env", { "reload-env" }, run_reload_env },
    { "4", "Контейнеры: логи", { "logs" }, run_logs },
    { "5", "Контейнеры: shell app", { "shell" }, run_shell },
    { "6", "Приложение: app.php команда", { "app" }, run_app_command },
    { "7", "Приложение: миграции", { "migrate" }, run_migrate },
    { "8", "Docker Compose: своя команда", { "compose" }, run_custom_compose },
}

local action_by_key = {}
for _, action in ipairs(actions) do
    action_by_key[action[1]] = action
    for _, alias in ipairs(action[3]) do
        action_by_key[alias] = action
    end
end

local function print_actions()
    io.stderr:write("Действия:\n")
    for _, action in ipairs(actions) do
        io.stderr:write(string.format("  %s) %s\n", action[1], action[2]))
    end
    io.stderr:write("  0) Выход\n")
end

local function run_selected_action(choice)
    if choice == "0" or choice == "q" or choice == "quit" or choice == "exit" then
        os.exit(0)
    end
    local action = action_by_key[choice]
    if not action then
        io.stderr:write("Ошибка: неизвестное действие '" .. choice .. "'.\n")
        return 1
    end
    local ok, status = pcall(action[4])
    if not ok then
        io.stderr:write("Ошибка: " .. tostring(status) .. "\n")
        return 1
    end
    return tonumber(status) or 0
end

if arg[1] == "-h" or arg[1] == "--help" then
    usage()
    os.exit(0)
end

if #arg > 0 then
    fail("Ошибка: интерактивная оболочка не является коротким alias для compose-команд.")
end

select_context()

while true do
    print_actions()
    local action = ask("Выберите действие", "1")
    local status = run_selected_action(action)
    if status ~= 0 then
        io.stderr:write("Действие завершилось с ошибкой: " .. tostring(status) .. "\n")
    end
    io.stderr:write("\n")
end

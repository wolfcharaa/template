#!/usr/bin/env lua5.3

local script_dir = (arg and arg[0] or ""):match("^(.*)/[^/]*$") or "."
package.path = "/usr/local/share/docker-lua/?.lua;/usr/local/share/docker-lua/?/init.lua;" ..
    script_dir .. "/../lua/?.lua;" .. script_dir .. "/../lua/?/init.lua;" .. package.path

local cli = require("spiral.cli")
local env = require("spiral.env")
local template = require("spiral.template")

local function fail(message)
    io.stderr:write("ERROR: " .. message .. "\n")
    os.exit(78)
end

local function load_values(options)
    local values = {}

    for _, path in ipairs(options.env_files or {}) do
        local ok, loaded = pcall(env.load_file, path)
        if not ok then
            fail(loaded)
        end
        env.merge(values, loaded)
    end

    env.with_process(values)
    cli.apply_set(values, options.set)
    return values
end

local function read_value(values, name, default)
    local value = values[name]
    if value == nil or value == "" then
        return default
    end
    return value
end

local function bool_ini(values, name, default)
    local ok, value = pcall(env.bool, values[name], default)
    if not ok then
        fail(name .. " must be 1, 0, true, false, yes, no, on, or off.")
    end
    return value and "1" or "0"
end

local function uint_ini(values, name, default)
    local ok, value = pcall(env.uint, values[name], default)
    if not ok then
        fail(name .. " must be an unsigned integer.")
    end
    return tostring(value)
end

local function size_ini(values, name, default, allow_unlimited)
    local value = tostring(read_value(values, name, default))

    if allow_unlimited and value == "-1" then
        return value
    end

    if not value:match("^%d+[KkMmGg]?$") then
        if allow_unlimited then
            fail(name .. " must be -1 or a size like 512M, 1G, or 65536.")
        end
        fail(name .. " must be a size like 128M, 1G, or 65536.")
    end

    return value
end

local options = cli.parse(arg)
local values = load_values(options)
local validate_timestamps_default = read_value(values, "APP_ENV", "") == "dev" and "1" or "0"

local runtime = {
    PHP_MEMORY_LIMIT = size_ini(values, "PHP_MEMORY_LIMIT", "-1", true),
    PHP_OPCACHE_ENABLE = bool_ini(values, "PHP_OPCACHE_ENABLE", "1"),
    PHP_OPCACHE_ENABLE_CLI = bool_ini(values, "PHP_OPCACHE_ENABLE_CLI", "1"),
    PHP_OPCACHE_VALIDATE_TIMESTAMPS = bool_ini(values, "PHP_OPCACHE_VALIDATE_TIMESTAMPS", validate_timestamps_default),
    PHP_OPCACHE_REVALIDATE_FREQ = uint_ini(values, "PHP_OPCACHE_REVALIDATE_FREQ", "0"),
    PHP_OPCACHE_MEMORY_CONSUMPTION = uint_ini(values, "PHP_OPCACHE_MEMORY_CONSUMPTION", "256"),
    PHP_OPCACHE_INTERNED_STRINGS_BUFFER = uint_ini(values, "PHP_OPCACHE_INTERNED_STRINGS_BUFFER", "32"),
    PHP_OPCACHE_MAX_ACCELERATED_FILES = uint_ini(values, "PHP_OPCACHE_MAX_ACCELERATED_FILES", "50000"),
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE = uint_ini(values, "PHP_OPCACHE_MAX_WASTED_PERCENTAGE", "10"),
    PHP_OPCACHE_FILE_UPDATE_PROTECTION = uint_ini(values, "PHP_OPCACHE_FILE_UPDATE_PROTECTION", "0"),
    PHP_OPCACHE_JIT_BUFFER_SIZE = size_ini(values, "PHP_OPCACHE_JIT_BUFFER_SIZE", "0", false),
    PHP_OPCACHE_USE_CWD = bool_ini(values, "PHP_OPCACHE_USE_CWD", "1"),
    PHP_OPCACHE_SAVE_COMMENTS = bool_ini(values, "PHP_OPCACHE_SAVE_COMMENTS", "1"),
    PHP_OPCACHE_ENABLE_FILE_OVERRIDE = bool_ini(values, "PHP_OPCACHE_ENABLE_FILE_OVERRIDE", "0"),
    PHP_OPCACHE_RECORD_WARNINGS = bool_ini(values, "PHP_OPCACHE_RECORD_WARNINGS", "1"),
    PHP_OPCACHE_VALIDATE_PERMISSION = bool_ini(values, "PHP_OPCACHE_VALIDATE_PERMISSION", "0"),
    PHP_OPCACHE_VALIDATE_ROOT = bool_ini(values, "PHP_OPCACHE_VALIDATE_ROOT", "0"),
}

local template_path = options.template or read_value(values, "PHP_RUNTIME_INI_TEMPLATE", "/usr/local/etc/php/conf.d/zz-runtime.ini.tpl")
local output_path = options.out or read_value(values, "PHP_RUNTIME_INI_OUTPUT", "/usr/local/etc/php/conf.d/zz-runtime.ini")
local ok, result = pcall(template.render_file, template_path, output_path, runtime)

if not ok then
    fail(result)
end

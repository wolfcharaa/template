#!/usr/bin/env lua5.3

local script_dir = (arg and arg[0] or ""):match("^(.*)/[^/]*$") or "."
local root_dir = script_dir:gsub("/?docker/scripts$", "")
if root_dir == "" then
    root_dir = "."
end
package.path = script_dir .. "/../lua/?.lua;" .. script_dir .. "/../lua/?/init.lua;" ..
    root_dir .. "/docker/lua/?.lua;" .. root_dir .. "/docker/lua/?/init.lua;" .. package.path

local data = require("project_data")

local function usage()
    io.write([[
Печатает план PostgreSQL dump-набора проекта.

Использование:
  docker/scripts/dump-plan.lua --set all --format shell

Опции:
  --set <name>       all, raw или runtime; по умолчанию all
  --format <name>    shell или text; по умолчанию text
  -h, --help         Показать справку
]])
end

local function fail(message)
    io.stderr:write("ERROR: " .. message .. "\n")
    os.exit(1)
end

local function shell_quote(value)
    value = tostring(value or "")
    return "'" .. value:gsub("'", [["'"']]) .. "'"
end

local set_name = "all"
local format = "text"
local index = 1

while index <= #arg do
    local value = arg[index]

    if value == "--set" then
        index = index + 1
        set_name = arg[index] or fail("--set requires a value")
    elseif value:match("^%-%-set=") then
        set_name = value:match("^%-%-set=(.*)$")
    elseif value == "--format" then
        index = index + 1
        format = arg[index] or fail("--format requires a value")
    elseif value:match("^%-%-format=") then
        format = value:match("^%-%-format=(.*)$")
    elseif value == "-h" or value == "--help" then
        usage()
        os.exit(0)
    else
        fail("unknown argument: " .. value)
    end

    index = index + 1
end

local ok, selected_tables = pcall(data.tables_for_set, set_name)
if not ok then
    fail(selected_tables)
end

local raw_tables = data.join(data.raw_tables)
local runtime_tables = data.join(data.runtime_tables)
local selected = data.join(selected_tables)
local export_raw = data.should_export_raw(set_name) and "1" or "0"
local export_runtime = data.should_export_runtime(set_name) and "1" or "0"

if format == "shell" then
    io.write("RAW_TABLES=" .. shell_quote(raw_tables) .. "\n")
    io.write("RUNTIME_TABLES=" .. shell_quote(runtime_tables) .. "\n")
    io.write("SELECTED_TABLES=" .. shell_quote(selected) .. "\n")
    io.write("EXPORT_RAW=" .. export_raw .. "\n")
    io.write("EXPORT_RUNTIME=" .. export_runtime .. "\n")
elseif format == "text" then
    io.write("set=" .. set_name .. "\n")
    io.write("export_raw=" .. export_raw .. "\n")
    io.write("export_runtime=" .. export_runtime .. "\n")
    io.write("raw_tables=" .. raw_tables .. "\n")
    io.write("runtime_tables=" .. runtime_tables .. "\n")
    io.write("selected_tables=" .. selected .. "\n")
else
    fail("--format must be shell or text")
end

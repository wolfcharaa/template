#!/usr/bin/env lua5.3

local script_dir = (arg and arg[0] or ""):match("^(.*)/[^/]*$") or "."
package.path = script_dir .. "/../lua/?.lua;" .. script_dir .. "/../lua/?/init.lua;" .. package.path

local cli = require("spiral.cli")
local env = require("spiral.env")

local function usage()
    io.write([[
Usage:
  check-env.lua --env-file config/.env APP_SECRET DATABASE_URL
  check-env.lua --env-file config/.env --require APP_SECRET --require DATABASE_URL
]])
end

local options = cli.parse(arg)
if options.help then
    usage()
    os.exit(0)
end

local values = {}
for _, path in ipairs(options.env_files) do
    env.merge(values, env.load_file(path))
end
values = env.with_process(values)

local required = {}
for _, key in ipairs(options.required) do
    table.insert(required, key)
end
for _, key in ipairs(options.positional) do
    table.insert(required, key)
end

if #required == 0 then
    io.stderr:write("ERROR: no required env names were provided\n")
    usage()
    os.exit(2)
end

local ok, err = pcall(function()
    env.require_keys(values, required)
end)

if not ok then
    io.stderr:write("ERROR: " .. err .. "\n")
    os.exit(1)
end

io.write("Env check: ok\n")

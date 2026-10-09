#!/usr/bin/env lua5.3

local script_dir = (arg and arg[0] or ""):match("^(.*)/[^/]*$") or "."
package.path = script_dir .. "/../lua/?.lua;" .. script_dir .. "/../lua/?/init.lua;" .. package.path

local cli = require("spiral.cli")
local env = require("spiral.env")
local template = require("spiral.template")

local function usage()
    io.write([[
Usage:
  render-template.lua --env-file config/.env --template input.tpl --out output
  render-template.lua --set NAME=value --template input.tpl --out output
]])
end

local options = cli.parse(arg)
if options.help then
    usage()
    os.exit(0)
end

local input = options.template or options.positional[1]
local output = options.out or options.positional[2]

if not input or not output then
    usage()
    os.exit(2)
end

local values = {}
for _, path in ipairs(options.env_files) do
    env.merge(values, env.load_file(path))
end
cli.apply_set(values, options.set)
values = env.with_process(values)

local ok, changed_or_error = pcall(function()
    return template.render_file(input, output, values)
end)

if not ok then
    io.stderr:write("ERROR: " .. changed_or_error .. "\n")
    os.exit(1)
end

if changed_or_error then
    io.write("Rendered: " .. output .. "\n")
else
    io.write("Already up to date: " .. output .. "\n")
end

#!/usr/bin/env lua5.3

local function fail(message)
    io.stderr:write("ERROR: " .. message .. "\n")
    os.exit(1)
end

local function indent_of(line)
    return #(line:match("^(%s*)") or "")
end

local input_path = arg[1]
local output_path = arg[2]

if not input_path or not output_path or arg[3] then
    fail("usage: sanitize-legacy-compose.lua <input-docker-compose.yaml> <output-docker-compose.yaml>")
end

local input = io.open(input_path, "r")
if not input then
    fail("compose file not found: " .. input_path)
end

local output = io.open(output_path, "w")
if not output then
    input:close()
    fail("cannot write compose file: " .. output_path)
end

output:write('version: "2.4"\n')

local skip_indent = nil
for line in input:lines() do
    if skip_indent then
        local indent = indent_of(line)
        if line == "" or indent > skip_indent then
            goto continue
        end
        skip_indent = nil
    end

    if line:match("^version:%s*") or line:match("^name:%s*") then
        goto continue
    end

    if line:match("^%s+platform:%s*") then
        goto continue
    end

    if line:match("^        deploy:%s*$") or line:match("^        profiles:%s*$") then
        skip_indent = 8
        goto continue
    end

    output:write(line .. "\n")

    ::continue::
end

input:close()
output:close()

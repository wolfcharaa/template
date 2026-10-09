#!/usr/bin/env lua5.3

local function usage()
    io.write([[
Читает line-oriented release manifest.

Использование:
  docker/release/manifest.lua --file docker/data/release/v1/source-manifest.txt --get release_version
  docker/release/manifest.lua --file docker/data/release/v1/source-manifest.txt --contains-image registry/app:v1

Опции:
  --file <path>            Manifest file
  --get <key>              Напечатать первое значение key=
  --contains-image <image> Проверить, что images содержит exact image
  -h, --help               Показать справку
]])
end

local function fail(message)
    io.stderr:write("ERROR: " .. message .. "\n")
    os.exit(1)
end

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalized_manifest_line(line)
    line = trim(line)
    if line:sub(1, 2) == "- " then
        line = line:sub(3)
    end
    return line
end

local function read_lines(path)
    local file = io.open(path, "r")
    if not file then
        fail("manifest file not found: " .. tostring(path))
    end

    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()
    return lines
end

local function manifest_value(lines, key)
    local prefix = key .. "="
    for _, line in ipairs(lines) do
        line = normalized_manifest_line(line)
        if line:sub(1, #prefix) == prefix then
            return line:sub(#prefix + 1)
        end
    end
    return nil
end

local function contains_image(lines, image)
    for _, line in ipairs(lines) do
        if trim(line) == "- " .. image then
            return true
        end
    end
    return false
end

local file_path = nil
local get_key = nil
local expected_image = nil
local index = 1

while index <= #arg do
    local value = arg[index]

    if value == "--file" then
        index = index + 1
        file_path = arg[index] or fail("--file requires a value")
    elseif value:match("^%-%-file=") then
        file_path = value:match("^%-%-file=(.*)$")
    elseif value == "--get" then
        index = index + 1
        get_key = arg[index] or fail("--get requires a value")
    elseif value:match("^%-%-get=") then
        get_key = value:match("^%-%-get=(.*)$")
    elseif value == "--contains-image" then
        index = index + 1
        expected_image = arg[index] or fail("--contains-image requires a value")
    elseif value:match("^%-%-contains%-image=") then
        expected_image = value:match("^%-%-contains%-image=(.*)$")
    elseif value == "-h" or value == "--help" then
        usage()
        os.exit(0)
    else
        fail("unknown argument: " .. value)
    end

    index = index + 1
end

if not file_path then
    fail("--file is required")
end
if not get_key and not expected_image then
    fail("--get or --contains-image is required")
end

local lines = read_lines(file_path)

if get_key then
    local value = manifest_value(lines, get_key)
    if value then
        io.write(value .. "\n")
    end
end

if expected_image and not contains_image(lines, expected_image) then
    os.exit(1)
end

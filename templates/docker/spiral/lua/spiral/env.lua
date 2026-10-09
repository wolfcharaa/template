local M = {}

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function starts_with(value, prefix)
    return value:sub(1, #prefix) == prefix
end

local function strip_inline_comment(value)
    local quote = nil
    local escaped = false

    for index = 1, #value do
        local char = value:sub(index, index)

        if escaped then
            escaped = false
        elseif char == "\\" then
            escaped = true
        elseif quote then
            if char == quote then
                quote = nil
            end
        elseif char == "'" or char == '"' then
            quote = char
        elseif char == "#" then
            local previous = value:sub(index - 1, index - 1)
            if index == 1 or previous:match("%s") then
                return trim(value:sub(1, index - 1))
            end
        end
    end

    return trim(value)
end

local function unescape_double_quoted(value)
    local replacements = {
        n = "\n",
        r = "\r",
        t = "\t",
        ['"'] = '"',
        ["\\"] = "\\",
    }

    return (value:gsub("\\(.)", function(char)
        return replacements[char] or char
    end))
end

function M.parse_line(line)
    line = trim(line or "")
    if line == "" or starts_with(line, "#") then
        return nil, nil
    end

    if starts_with(line, "export ") then
        line = trim(line:sub(8))
    end

    local name, raw = line:match("^([A-Za-z_][A-Za-z0-9_]*)%s*=%s*(.*)$")
    if not name then
        return nil, "invalid env line: " .. line
    end

    raw = strip_inline_comment(raw)
    local first = raw:sub(1, 1)
    local last = raw:sub(-1)

    if first == "'" and last == "'" and #raw >= 2 then
        raw = raw:sub(2, -2)
    elseif first == '"' and last == '"' and #raw >= 2 then
        raw = unescape_double_quoted(raw:sub(2, -2))
    end

    return name, raw
end

function M.load_file(path, options)
    options = options or {}
    local values = {}

    if not path or path == "" then
        return values
    end

    local file = io.open(path, "r")
    if not file then
        if options.optional then
            return values
        end
        error("env file not found: " .. path)
    end

    local line_number = 0
    for line in file:lines() do
        line_number = line_number + 1
        local name, value_or_error = M.parse_line(line)
        if name then
            values[name] = value_or_error
        elseif value_or_error then
            file:close()
            error(path .. ":" .. line_number .. ": " .. value_or_error)
        end
    end

    file:close()
    return values
end

function M.merge(target, source)
    target = target or {}
    for key, value in pairs(source or {}) do
        target[key] = value
    end
    return target
end

function M.with_process(values)
    values = values or {}
    return setmetatable(values, {
        __index = function(_, key)
            return os.getenv(key)
        end,
    })
end

function M.require_keys(values, keys)
    local missing = {}
    values = values or {}

    for _, key in ipairs(keys or {}) do
        local value = values[key]
        if value == nil or value == "" then
            table.insert(missing, key)
        end
    end

    if #missing > 0 then
        error("missing required env: " .. table.concat(missing, ", "))
    end
end

function M.bool(value, default)
    if value == nil or value == "" then
        value = default
    end
    if value == true or value == "1" or value == "true" or value == "TRUE" or value == "yes" or value == "YES" or value == "on" or value == "ON" then
        return true
    end
    if value == false or value == "0" or value == "false" or value == "FALSE" or value == "no" or value == "NO" or value == "off" or value == "OFF" then
        return false
    end
    error("expected boolean value, got: " .. tostring(value))
end

function M.uint(value, default)
    if value == nil or value == "" then
        value = default
    end
    value = tostring(value or "")
    if not value:match("^%d+$") then
        error("expected unsigned integer, got: " .. value)
    end
    return tonumber(value)
end

function M.size(value, default)
    if value == nil or value == "" then
        value = default
    end
    value = tostring(value or "")
    if value ~= "-1" and not value:match("^%d+[KkMmGg]?$") then
        error("expected size like 128M, 1G, 65536, or -1; got: " .. value)
    end
    return value
end

return M

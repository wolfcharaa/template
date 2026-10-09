local M = {}

local function read_file(path)
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
end

local function write_file(path, content)
    local tmp = path .. ".tmp." .. tostring(os.time()) .. "." .. tostring(math.random(100000, 999999))
    local file = assert(io.open(tmp, "w"))
    file:write(content)
    file:close()
    assert(os.rename(tmp, path))
end

function M.render_string(content, values)
    local missing = {}

    local rendered = content:gsub("{{%s*([A-Za-z_][A-Za-z0-9_]*)%s*}}", function(name)
        local value = values and values[name]
        if value == nil then
            table.insert(missing, name)
            return ""
        end
        return tostring(value)
    end)

    if #missing > 0 then
        error("missing template values: " .. table.concat(missing, ", "))
    end

    return rendered
end

function M.render_file(input_path, output_path, values)
    local rendered = M.render_string(read_file(input_path), values)
    local current = nil
    local existing = io.open(output_path, "r")

    if existing then
        current = existing:read("*a")
        existing:close()
    end

    if current ~= rendered then
        write_file(output_path, rendered)
        return true
    end

    return false
end

return M

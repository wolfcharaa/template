local M = {}

-- Replace these examples with the project's real prepared-data table sets.
M.raw_tables = {
    "import_source",
    "import_item",
    "import_log",
}

M.runtime_tables = {
    "search_document",
    "search_alias",
}

function M.should_export_raw(set_name)
    return set_name == "all" or set_name == "raw"
end

function M.should_export_runtime(set_name)
    return set_name == "all" or set_name == "runtime"
end

function M.validate_set(set_name)
    if set_name ~= "all" and set_name ~= "raw" and set_name ~= "runtime" then
        error("dump set must be all, raw, or runtime")
    end
end

local function append_all(target, source)
    for _, value in ipairs(source) do
        table.insert(target, value)
    end
end

function M.tables_for_set(set_name)
    M.validate_set(set_name)

    local tables = {}
    if M.should_export_raw(set_name) then
        append_all(tables, M.raw_tables)
    end
    if M.should_export_runtime(set_name) then
        append_all(tables, M.runtime_tables)
    end

    return tables
end

function M.join(values)
    return table.concat(values, " ")
end

return M

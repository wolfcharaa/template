local M = {}

local function fail(message)
    io.stderr:write("ERROR: " .. message .. "\n")
    os.exit(2)
end

function M.parse(argv)
    local options = {
        env_files = {},
        required = {},
        set = {},
        positional = {},
    }

    local index = 1
    while index <= #argv do
        local arg = argv[index]

        if arg == "--env-file" then
            index = index + 1
            if not argv[index] then
                fail("--env-file requires a value")
            end
            table.insert(options.env_files, argv[index])
        elseif arg:match("^%-%-env%-file=") then
            table.insert(options.env_files, arg:match("^%-%-env%-file=(.*)$"))
        elseif arg == "--require" then
            index = index + 1
            if not argv[index] then
                fail("--require requires a value")
            end
            table.insert(options.required, argv[index])
        elseif arg:match("^%-%-require=") then
            table.insert(options.required, arg:match("^%-%-require=(.*)$"))
        elseif arg == "--set" then
            index = index + 1
            if not argv[index] then
                fail("--set requires KEY=VALUE")
            end
            table.insert(options.set, argv[index])
        elseif arg:match("^%-%-set=") then
            table.insert(options.set, arg:match("^%-%-set=(.*)$"))
        elseif arg == "--template" then
            index = index + 1
            if not argv[index] then
                fail("--template requires a value")
            end
            options.template = argv[index]
        elseif arg:match("^%-%-template=") then
            options.template = arg:match("^%-%-template=(.*)$")
        elseif arg == "--out" then
            index = index + 1
            if not argv[index] then
                fail("--out requires a value")
            end
            options.out = argv[index]
        elseif arg:match("^%-%-out=") then
            options.out = arg:match("^%-%-out=(.*)$")
        elseif arg == "-h" or arg == "--help" then
            options.help = true
        else
            table.insert(options.positional, arg)
        end

        index = index + 1
    end

    return options
end

function M.apply_set(values, assignments)
    for _, assignment in ipairs(assignments or {}) do
        local key, value = assignment:match("^([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
        if not key then
            fail("--set expects KEY=VALUE, got: " .. assignment)
        end
        values[key] = value
    end
end

return M

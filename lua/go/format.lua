local M = {}

local vim = vim
local config = require('go.config')
local system = require('go.system')
local output = require('go.output')
local util = require('go.util')

function M.format(fmt)
    if not config.is_set(config.options.formatter) then
        return
    end
    local formatter = config.options.formatter
    if fmt ~= nil then
        formatter = fmt
    end
    return pcall(M[formatter])
end

local function arrayEqual(x, y)
    if #x ~= #y then
        return false
    end
    for k, v in pairs(x) do
        if y[k] ~= v then
            return false
        end
    end

    return true
end

local function do_fmt(formatter, args)
    if not util.binary_exists(formatter) then
        return
    end
    local buf_nr = vim.api.nvim_get_current_buf()
    local content = vim.api.nvim_buf_get_lines(buf_nr, 0, -1, true)
    -- goimports stdout result
    local result = vim.fn.systemlist(system.wrap_command(formatter, args), content)
    if vim.v.shell_error == 0 then
        if not arrayEqual(content, result) then
            vim.api.nvim_buf_set_lines(buf_nr, 0, -1, true, result)
        end
        output.show_success('GoFormat', 'Success')
    else
        output.show_error('GoFormat', 'error '..table.concat(result, '\n'))
    end
end

function M.gofmt()
    do_fmt('gofmt', {})
end

function M.goimports()
    do_fmt('goimports', { })
end

function M.gofumpt()
    do_fmt('gofumpt', { '-l' })
end

return M

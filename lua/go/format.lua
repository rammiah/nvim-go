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

local function do_fmt(formatter, args)
    if not util.binary_exists(formatter) then
        return
    end
    local buf_nr = vim.api.nvim_get_current_buf()
    local content = vim.api.nvim_buf_get_lines(buf_nr, 0, -1, true)
    local view = vim.fn.winsaveview()
    -- goimports stdout result
    local result = {}
    local cmd = system.wrap_command(formatter, args)
    local id = vim.fn.jobstart({cmd}, {
        on_exit = function(_, code, _)
            if code == 0 then
                output.show_success('GoFormat', 'Success')
                -- set out lines
                vim.api.nvim_buf_set_lines(buf_nr, 0, -1, true, result)
                vim.fn.winrestview(view)
            end
            vim.api.nvim_exec('noautocmd write', true)
        end,
        on_stderr = function(_, data, _)
            if #data == 0 or #data[1] == 0 then
                return
            end
            local results = 'File is not formatted due to error.\n'
                .. table.concat(data, '\n')
            output.show_error('GoFormat', results)
        end,
        stdout_buffered = true, -- goimports output
        on_stdout = function (_, data, _)
            result = data
        end,
    })
    vim.fn.chansend(id, content)
    vim.fn.chanclose(id, 'stdin')
end

function M.gofmt()
    do_fmt('gofmt', {})
end

function M.goimports()
    do_fmt('goimports', {})
end

function M.gofumpt()
    do_fmt('gofumpt', { '-l' })
end

return M

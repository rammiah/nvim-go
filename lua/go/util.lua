local M = {}

local vim = vim
local output = require("go.output")

function M.current_word()
    return vim.fn.expand("<cword>")
end

function M.current_line()
    return vim.fn.getline(".")
end

function M.binary_exists(bin)
    if vim.fn.executable(bin) == 1 then
        return true
    end
    output.show_error(
        "No Binary",
        string.format("%s not exists. Run `:GoInstallBinaries`", bin)
    )
    return false
end

function M.empty_output(data)
    if #data == 0 then
        return true
    end
    if #data == 1 and data[1] == "" then
        return true
    end

    return false
end

function M.slice(obj, start, finish)
    if obj == nil or #obj == 0 or start == finish then return {} end

    local output = {}
    local _finish = #obj
    local _start = 1

    if start >= 0 then
      _start = start
    elseif finish == nil and start < 0 then
      _start = #obj + start + 1
    end

    if (finish and finish >= 0) then
      _finish = finish - 1
    elseif finish and finish < 0 then
      _finish = #obj + finish
    end

    for i = _start, _finish do
      table.insert(output, obj[i])
    end

    return output
end

function M.apply_diffs(diffs, bufnr)
    -- at least 3 lines with diff out header
    if #diffs <= 3 then
        return
    end
    local diffs = M.slice(diffs, 4)
    -- parse diff into a replace table
    local old_lines = {}
    local new_lines = {}
    local line = 0

    for _, l in ipairs(diffs) do
        if l:match("^@@") then
            -- check before is a delete or append or replace
            if #old_lines ~= 0 or #new_lines ~= 0 then
                vim.api.nvim_buf_set_lines(bufnr, line, line + #old_lines, true, new_lines)
            end
            -- reset indexes to diff
            line = l:match("@@ %-%d+,%d+ %+(%d+),%d+ @@")
            line = tonumber(line) - 1 -- refer to line before current
            new_lines = {}
            old_lines = {}
        elseif l:match("^%-") then
            table.insert(old_lines, l:match("^%-(.*)$"))
        elseif l:match("^%+") then
            table.insert(new_lines, l:match("^%+(.*)$"))
        elseif l:match("^ ") then
            -- delete old lines, add new lines, replace lines
            if #old_lines ~= 0 or #new_lines ~= 0 then
                vim.api.nvim_buf_set_lines(bufnr, line, line + #old_lines, true, new_lines)
                line = line + #new_lines
                new_lines = {}
                old_lines = {}
            end
            line = line + 1
        end
    end
end

return M

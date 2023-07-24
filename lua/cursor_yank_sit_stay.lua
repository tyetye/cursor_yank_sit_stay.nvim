package.loaded['cursor_yank_sit_stay'] = nil
-- File: ~/.config/nvim/lua/cursor_yank_sit_stay.lua
local M = {}

-- Default configuration
M.config = {
    highlight_group = 'IncSearch',
    highlight_durations = {
        char = 1000,
        line = 500,
        -- block = 5000,  -- saved for later for V-BLOCK mode
    },
    enabled = true,
}

-- Cursor State
M.cursor_state = {
    position = nil,
    win_state = nil,
}

-- Helper function to set state and print message
local function set_enabled_state_and_print_message(enabled_state)
    M.config.enabled = enabled_state
    print("CursorYankSitStay is " .. (enabled_state and "enabled" or "disabled") .. ".")
end

-- Helper function to reset cursor state
local function reset_cursor_state()
    M.cursor_state = {
        position = nil,
        win_state = nil,
    }
end

-- Enable plugin
function M.enable()
    set_enabled_state_and_print_message(true)
end

-- Disable plugin
function M.disable()
    set_enabled_state_and_print_message(false)
end

-- Toggle plugin
function M.toggle()
    set_enabled_state_and_print_message(not M.config.enabled)
end

-- Highlight yanked area and restore cursor position after yank
function M.yank_post()
    if not M.config.enabled or vim.v.event.operator ~= 'y' then
        return
    end

    -- Determine the type of yank and its corresponding duration
    local duration
    if vim.v.event.regtype == 'v' then
        duration = M.config.highlight_durations.char
    elseif vim.v.event.regtype == 'V' then
        duration = M.config.highlight_durations.line
    else
        duration = 500  -- default duration
    end

    -- Highlight yanked area
    vim.highlight.on_yank({ higroup = M.config.highlight_group, timeout = duration })

    -- Restore cursor position and window view state
    if nil ~= M.cursor_state.position then
        vim.fn.setpos(".", M.cursor_state.position)
        vim.fn.winrestview(M.cursor_state.win_state)
    end

    -- Re-save the cursor position and window state
    M.cursor_state = {
        position = vim.fn.getpos("."),
        win_state = vim.fn.winsaveview(),
    }
end

-- Save cursor position and window view state before yank
function M.yank_pre()
    if not M.config.enabled then
        return
    end

    M.cursor_state = {
        position = vim.fn.getpos("."),
        win_state = vim.fn.winsaveview(),
    }

    -- Reset state if lines in buffer are changed
    vim.api.nvim_buf_attach(0, false, {
        on_lines = function()
            reset_cursor_state()

            return true
        end,
    })
end

-- Set up autocommands
function M.setup(user_config)
    -- Override default config with user config
    M.config = vim.tbl_extend('force', M.config, user_config or {})

    -- Define Neovim commands for enabling, disabling, and toggling the plugin
    vim.cmd [[
    command! CursorYankSitStayEnable lua require('cursor_yank_sit_stay').enable()
    command! CursorYankSitStayDisable lua require('cursor_yank_sit_stay').disable()
    command! CursorYankSitStayToggle lua require('cursor_yank_sit_stay').toggle()
    ]]

    vim.cmd [[
    augroup cursor_yank_sit_stay
    autocmd!
    autocmd CursorMoved * lua require('cursor_yank_sit_stay').yank_pre()
    autocmd TextYankPost * lua require('cursor_yank_sit_stay').yank_post()
    augroup END
    ]]
end

return M


-- terminal.lua
--
-- Keymaps:
--   <C-t>  normal mode (any buffer)   → open terminal, enter insert mode
--   <C-t>  terminal insert mode       → hide terminal, return to prev window
--   <C-t>  terminal normal mode       → hide terminal, return to prev window
--   <C-q>  terminal insert mode       → exit insert only, keep window open
--   <C-i>  terminal normal mode       → re-enter insert mode (buffer-local)

local api = vim.api
local M = {}

-- ── State ──────────────────────────────────────────────────────────────────

local state = {
  bufnr = nil, -- the persistent terminal buffer
  winid = nil, -- the terminal window (nil when hidden)
  prev_winid = nil, -- window to return focus to after hiding
  opening = false, -- guard: prevents re-entrant calls to show_terminal
}

-- ── Helpers ────────────────────────────────────────────────────────────────

local function buf_valid()
  return state.bufnr and api.nvim_buf_is_valid(state.bufnr)
end

local function win_valid()
  return state.winid and api.nvim_win_is_valid(state.winid)
end

local function get_term_wins()
  if not buf_valid() then
    return {}
  end
  return vim.fn.win_findbuf(state.bufnr)
end

local function feed(keys)
  api.nvim_feedkeys(api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

-- Buffer-local maps set once when the terminal buffer is first created.
-- <C-i> is kept buffer-local so it doesn't clobber jump-forward elsewhere.
local function setup_term_buf_maps(bufnr)
  vim.keymap.set("n", "<C-i>", function()
    vim.cmd "startinsert"
  end, { buffer = bufnr, desc = "Re-enter terminal insert mode" })
end

-- ── Core ───────────────────────────────────────────────────────────────────

local function create_terminal(prev_win)
  vim.cmd "botright 15split"
  state.winid = api.nvim_get_current_win()
  state.prev_winid = prev_win

  -- Create a fresh empty scratch buffer and place it in the new window.
  -- botright 15split reuses the current buffer in the split, and termopen
  -- refuses to run in a buffer that already has content.
  local scratch = api.nvim_create_buf(false, true)
  api.nvim_win_set_buf(state.winid, scratch)

  vim.fn.termopen(vim.o.shell, {
    on_exit = function()
      state.bufnr = nil
      state.winid = nil
    end,
  })

  state.bufnr = api.nvim_get_current_buf()

  -- Set a custom filetype so lualine can target this buffer specifically
  -- with its own extension (dark theme, terminal-aware components).
  -- Must be set after termopen so it isn't overwritten by the terminal setup.
  vim.schedule(function()
    if buf_valid() then
      vim.bo[state.bufnr].filetype = "jeffterm"
    end
  end)

  setup_term_buf_maps(state.bufnr)
end

function M.show_terminal()
  if state.opening then
    return
  end
  state.opening = true

  local caller_win = api.nvim_get_current_win()

  if not buf_valid() then
    create_terminal(caller_win)
  else
    local wins = get_term_wins()
    if #wins > 0 then
      state.winid = wins[1]
      api.nvim_set_current_win(state.winid)
    else
      state.prev_winid = caller_win
      vim.cmd "botright 15split"
      state.winid = api.nvim_get_current_win()
      api.nvim_win_set_buf(state.winid, state.bufnr)
    end
  end

  vim.schedule(function()
    state.opening = false
    if win_valid() then
      api.nvim_set_current_win(state.winid)
      vim.cmd "startinsert"
    end
  end)
end

function M.hide_terminal()
  for _, win in ipairs(get_term_wins()) do
    if #api.nvim_list_wins() > 1 then
      api.nvim_win_close(win, false)
    end
  end
  state.winid = nil

  if state.prev_winid and api.nvim_win_is_valid(state.prev_winid) then
    api.nvim_set_current_win(state.prev_winid)
  end
end

function M.toggle_terminal()
  local buftype = vim.bo[api.nvim_get_current_buf()].buftype
  if buftype == "terminal" then
    M.hide_terminal()
  else
    M.show_terminal()
  end
end

-- ── Keymaps ────────────────────────────────────────────────────────────────

vim.keymap.set("n", "<C-t>", M.toggle_terminal, { desc = "Toggle terminal" })

vim.keymap.set("t", "<C-t>", function()
  feed "<C-\\><C-n>"
  vim.schedule(M.hide_terminal)
end, { desc = "Hide terminal" })

vim.keymap.set("t", "<C-q>", function()
  feed "<C-\\><C-n>"
end, { desc = "Exit terminal insert mode" })

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if buf_valid() then
      local job_id = vim.b[state.bufnr].terminal_job_id
      if job_id then
        vim.fn.jobstop(job_id)
      end
    end
  end,
})
return M

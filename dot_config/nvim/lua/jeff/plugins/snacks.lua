return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,

  ---@type snacks.Config
  opts = {
    -- terminal = {
    --   -- Default bottom split settings
    --   split = {
    --     direction = "horizontal",
    --     size = 20,
    --     startinsert = true,
    --   },
    -- },
    bigfile = { enabled = false },
    dashboard = {
      enabled = true,
      preset = {
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "p", desc = "Find Project", action = "<leader>fp" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    },
    explorer = { enabled = false },
    indent = { enabled = false },
    input = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 2500,
    },
    picker = {
      enabled = false,
      sources = {
        projects = {
          layout = {
            preset = "dropdown",
            width = 0.4,
            height = 04,
            preview = false,
          },
        },
      },
    },
    quickfile = { enabled = true },
    scope = { enabled = false },
    scroll = { enabled = true },
    statuscolumn = { enabled = false },
    words = { enabled = true },
    styles = {
      notification = {
        -- wo = { wrap = true } -- Wrap notifications
      },
    },
  },
  keys = {
    -- {
    --   "<leader>t",
    --   function()
    --     -- Toggle a bottom split terminal
    --     Snacks.terminal(nil, { win = term_opts.split })
    --     -- Snacks.terminal.toggle(term_opts.split)
    --   end,
    --   desc = "Toggle bottom split terminal",
    -- },
    -- {
    --   "<leader>tt",
    --   function()
    --     -- Open a floating terminal for quick tasks
    --     Snacks.terminal(nil, { win = term_opts.popup })
    --     -- Snacks.terminal.floating(term_opts.popup)
    --   end,
    --   desc = "Open floating terminal",
    -- },
    {
      "<leader>gg",
      function()
        Snacks.lazygit { cwd = Snacks.git.get_root() }
      end,
      desc = "Lazygit",
    },
    {
      "<leader>fp",
      function()
        Snacks.picker.projects()
      end,
      desc = "Projects",
    },
    {
      "<leader>.",
      function()
        Snacks.scratch()
      end,
      desc = "Toggle Scratch Buffer",
    },
    {
      "<leader>bd",
      function()
        Snacks.bufdelete()
      end,
      desc = "Delete current Buffer",
    },
    {
      "]]",
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = "Next Reference",
      mode = { "n", "t" },
    },
    {
      "[[",
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = "Prev Reference",
      mode = { "n", "t" },
    },
  },

  init = function()
    -- local term_bufnr = nil
    -- local term_winid = nil
    --
    -- -- vim.api.nvim_set_keymap("n", "<leader>t", "<cmd>lua TogglePersistentTerm()<CR>", { noremap = true, silent = true })
    --
    -- function TogglePersistentTerm()
    --   local api = vim.api
    --   if term_winid and api.nvim_win_is_valid(term_winid) then
    --     -- Terminal is open, hide it and return to previous buffer
    --     api.nvim_win_hide(term_winid)
    --     api.nvim_set_current_buf(api.nvim_get_current_buf())
    --   else
    --     -- Create terminal buffer if missing
    --     if not term_bufnr or not api.nvim_buf_is_valid(term_bufnr) then
    --       term_bufnr = api.nvim_create_buf(false, true) -- scratch buffer
    --       api.nvim_buf_set_name(term_bufnr, "PersistentTerm")
    --       vim.fn.termopen(os.getenv "SHELL" or "/bin/zsh")
    --     end
    --
    --     -- Open bottom split and attach buffer
    --     api.nvim_command "botright 15split"
    --     term_winid = api.nvim_get_current_win()
    --     api.nvim_win_set_buf(term_winid, term_bufnr)
    --     api.nvim_command "startinsert"
    --   end
    -- end
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map "<leader>us"
        Snacks.toggle.option("wrap", { name = "Wrap" }):map "<leader>uw"
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map "<leader>uL"
        Snacks.toggle.diagnostics():map "<leader>ud"
        Snacks.toggle.line_number():map "<leader>ul"
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map "<leader>uc"
        Snacks.toggle.treesitter():map "<leader>uT"
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map "<leader>ub"
        Snacks.toggle.inlay_hints():map "<leader>uh"
        Snacks.toggle.indent():map "<leader>ug"
        Snacks.toggle.dim():map "<leader>uD"
      end,
    })
  end,
}

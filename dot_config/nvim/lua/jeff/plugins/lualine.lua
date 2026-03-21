return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "catppuccin/nvim",
  },
  config = function()
    local lualine = require "lualine"
    local custom_catppuccin = require "catppuccin.utils.lualine"()
    local theme = custom_catppuccin
    local lazy_status = require "lazy.status"

    -- Pretty location
    local function emoji_location()
      return "📍 " .. vim.fn.line "." .. ":" .. vim.fn.virtcol "."
    end

    -- Make all sections (a, b, c, x, y, z) in each mode use the same color
    for _, mode in pairs(custom_catppuccin) do
      if mode.a and mode.a.bg and mode.a.fg then
        local fg = mode.a.fg
        local bg = mode.a.bg
        for _, section in ipairs { "a", "b", "c", "x", "y", "z" } do
          mode[section] = { fg = fg, bg = bg }
        end
      end
    end

    -- ── Terminal extension ────────────────────────────────────────────────
    -- Targets buffers with filetype "jeffterm" (set in terminal.lua).
    -- Uses dark catppuccin surface colors so it's visually distinct from
    -- regular buffers while keeping the same component layout.

    local palette = require("catppuccin.palettes").get_palette()

    -- Dark flat theme: same structure as your main theme but using surface
    -- tones from catppuccin (mantle/crust for bg, subtext for fg).
    local term_bg = palette.mantle
    local term_fg = palette.subtext1

    local dark = { fg = term_fg, bg = term_bg }
    local name = { fg = palette.subtext1, bg = palette.surface1 }

    local term_colors = {
      -- Normal mode in terminal (navigating with vim keys after <C-q>)
      normal = {
        a = { fg = palette.subtext1, bg = palette.surface1 },
        b = { fg = palette.subtext0, bg = palette.surface0 },
        c = { fg = palette.overlay1, bg = palette.mantle },
        x = { fg = palette.overlay1, bg = palette.mantle },
        y = { fg = palette.subtext0, bg = palette.surface0 },
        z = { fg = palette.subtext1, bg = palette.surface1 },
      },
      -- Insert (terminal typing) mode
      insert = {
        a = { fg = palette.base, bg = palette.teal },
        b = { fg = palette.subtext0, bg = palette.surface0 },
        c = { fg = palette.overlay1, bg = palette.mantle },
        x = { fg = palette.overlay1, bg = palette.mantle },
        y = { fg = palette.subtext0, bg = palette.surface0 },
        z = { fg = palette.base, bg = palette.teal },
      },
    }

    -- Shell name extracted from the buffer name (e.g. "zsh", "bash").
    -- Falls back to vim.o.shell if the buffer name isn't the usual term:// form.
    local function term_name()
      local bufname = vim.api.nvim_buf_get_name(0)
      local shell = bufname:match "/([^/]+)$" or vim.fn.fnamemodify(vim.o.shell, ":t")
      return " " .. shell
    end

    -- Working directory, shortened to just the last two path components
    -- so it fits comfortably in the statusline.
    local function term_cwd()
      local cwd = vim.fn.getcwd()
      local parts = vim.split(cwd, "/", { trimempty = true })
      if #parts >= 2 then
        return "  " .. parts[#parts - 1] .. "/" .. parts[#parts]
      end
      return "  " .. (parts[#parts] or cwd)
    end

    local terminal_extension = {
      -- Lualine matches extensions by filetype.
      -- "jeffterm" is set on our terminal buffer in terminal.lua.
      filetypes = { "jeffterm" },

      sections = {
        lualine_a = { "mode" },

        lualine_b = {
          {
            term_name,
            color = { fg = term_colors.normal.b.fg, bg = term_colors.normal.b.bg },
          },
        },

        lualine_c = {
          {
            term_cwd,
            color = { fg = term_colors.normal.c.fg, bg = term_colors.normal.c.bg },
          },
        },

        lualine_x = {}, -- no filetype / lazy updates needed in terminal

        lualine_y = {
          {
            "progress",
            color = { fg = term_colors.normal.y.fg, bg = term_colors.normal.y.bg },
          },
        },

        lualine_z = { emoji_location },
      },
    }

    local claude_extension = {
      filetypes = { "claudecode_term" },
      sections = {
        lualine_a = {
          {
            function()
              return "Claude Code"
            end,
            color = { name },
          },
        },
        lualine_b = { {
          function()
            return ""
          end,
          color = dark,
        } },
        lualine_c = { {
          function()
            return ""
          end,
          color = dark,
        } },
        lualine_x = { {
          function()
            return ""
          end,
          color = dark,
        } },
        lualine_y = { {
          function()
            return ""
          end,
          color = dark,
        } },
        lualine_z = { {
          function()
            return ""
          end,
          color = dark,
        } },
      },
      -- options = {
      --   theme = {
      --     normal = {
      --       a = { fg = palette.subtext1, bg = palette.surface1 },
      --       b = { fg = term_fg, bg = term_bg },
      --       c = { fg = term_fg, bg = term_bg },
      --       x = { fg = term_fg, bg = term_bg },
      --       y = { fg = term_fg, bg = term_bg },
      --       z = { fg = term_fg, bg = term_bg },
      --     },
      --     insert = {
      --       a = { fg = palette.subtext1, bg = palette.surface1 },
      --       b = { fg = term_fg, bg = term_bg },
      --       c = { fg = term_fg, bg = term_bg },
      --       x = { fg = term_fg, bg = term_bg },
      --       y = { fg = term_fg, bg = term_bg },
      --       z = { fg = term_fg, bg = term_bg },
      --     },
      --     visual = {
      --       a = { fg = palette.subtext1, bg = palette.surface1 },
      --       b = { fg = term_fg, bg = term_bg },
      --       c = { fg = term_fg, bg = term_bg },
      --       x = { fg = term_fg, bg = term_bg },
      --       y = { fg = term_fg, bg = term_bg },
      --       z = { fg = term_fg, bg = term_bg },
      --     },
      --     terminal = {
      --       a = { fg = palette.subtext1, bg = palette.surface1 },
      --       b = { fg = term_fg, bg = term_bg },
      --       c = { fg = term_fg, bg = term_bg },
      --       x = { fg = term_fg, bg = term_bg },
      --       y = { fg = term_fg, bg = term_bg },
      --       z = { fg = term_fg, bg = term_bg },
      --     },
      --   },
      -- },
    }

    local opencode_extension = {
      filetypes = { "opencode_term" },
      sections = {
        lualine_a = {
          {
            function()
              return "OpenCode"
            end,
            color = { fg = palette.subtext1, bg = palette.surface1 },
          },
        },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
      options = {
        theme = {
          normal = {
            a = { fg = palette.subtext1, bg = palette.surface1 },
            b = { fg = term_fg, bg = term_bg },
            c = { fg = term_fg, bg = term_bg },
            x = { fg = term_fg, bg = term_bg },
            y = { fg = term_fg, bg = term_bg },
            z = { fg = term_fg, bg = term_bg },
          },
          insert = {
            a = { fg = palette.subtext1, bg = palette.surface1 },
            b = { fg = term_fg, bg = term_bg },
            c = { fg = term_fg, bg = term_bg },
            x = { fg = term_fg, bg = term_bg },
            y = { fg = term_fg, bg = term_bg },
            z = { fg = term_fg, bg = term_bg },
          },
          visual = {
            a = { fg = palette.subtext1, bg = palette.surface1 },
            b = { fg = term_fg, bg = term_bg },
            c = { fg = term_fg, bg = term_bg },
            x = { fg = term_fg, bg = term_bg },
            y = { fg = term_fg, bg = term_bg },
            z = { fg = term_fg, bg = term_bg },
          },
          terminal = {
            a = { fg = palette.subtext1, bg = palette.surface1 },
            b = { fg = term_fg, bg = term_bg },
            c = { fg = term_fg, bg = term_bg },
            x = { fg = term_fg, bg = term_bg },
            y = { fg = term_fg, bg = term_bg },
            z = { fg = term_fg, bg = term_bg },
          },
        },
      },
    }

    -- ── Main setup ───────────────────────────────────────────────────────

    lualine.setup {
      options = {
        theme = custom_catppuccin,
        component_separators = "",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {
          {
            "branch",
            icon = "",
            color = function()
              local mode = vim.fn.mode()
              local fg = (theme[mode] and theme[mode].a.fg) or theme.normal.a.fg
              return { fg = fg }
            end,
          },
        },
        lualine_c = {
          {
            "filename",
            path = 1,
          },
        },
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = function()
              local mode = vim.fn.mode()
              local fg = (theme[mode] and theme[mode].a.fg) or theme.normal.a.fg
              return { fg = fg }
            end,
          },
          {
            "filetype",
            icon_only = false,
            color = function()
              local mode = vim.fn.mode()
              local fg = (theme[mode] and theme[mode].a.fg) or theme.normal.a.fg
              return { fg = fg }
            end,
          },
        },
        lualine_y = { "progress" },
        lualine_z = { emoji_location },
      },
      extensions = { terminal_extension, claude_extension, opencode_extension },
    }

    vim.api.nvim_create_autocmd("ModeChanged", {
      pattern = "*",
      callback = function()
        vim.cmd "redrawstatus"
      end,
    })
  end,
}

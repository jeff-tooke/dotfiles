return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "catppuccin/nvim",
  },
  config = function()
    local lualine = require "lualine"
    local lazy_status = require "lazy.status"
    local palette = require("catppuccin.palettes").get_palette()

    -- ── Colors ────────────────────────────────────────────────────────────

    local bg = palette.mantle -- single flat bar background everywhere
    local fg = palette.subtext1 -- default readable text
    local fg_dim = palette.overlay1 -- dimmed text (progress, cwd)

    -- Mode accent: only the pill + arrow change color, nothing else
    local mode_colors = {
      n = palette.blue,
      i = palette.green,
      v = palette.mauve,
      V = palette.mauve,
      ["\22"] = palette.mauve, -- <C-v> block visual
      c = palette.peach,
      s = palette.teal,
      S = palette.teal,
      R = palette.red,
      r = palette.red,
      t = palette.teal,
    }

    local function accent()
      return mode_colors[vim.fn.mode()] or palette.blue
    end

    -- ── Flat dark theme ───────────────────────────────────────────────────
    -- ALL sections (a–z) are set to dark for every mode.
    -- This is the critical fix: if any section is unspecified lualine falls
    -- back to an internal default that can be bright/visible.
    -- Component-level `color` opts override these per-component as needed.

    local dark_sec = { fg = fg, bg = bg }
    local flat_theme = {
      normal = { a = dark_sec, b = dark_sec, c = dark_sec, x = dark_sec, y = dark_sec, z = dark_sec },
      insert = { a = dark_sec, b = dark_sec, c = dark_sec, x = dark_sec, y = dark_sec, z = dark_sec },
      visual = { a = dark_sec, b = dark_sec, c = dark_sec, x = dark_sec, y = dark_sec, z = dark_sec },
      replace = { a = dark_sec, b = dark_sec, c = dark_sec, x = dark_sec, y = dark_sec, z = dark_sec },
      command = { a = dark_sec, b = dark_sec, c = dark_sec, x = dark_sec, y = dark_sec, z = dark_sec },
      terminal = { a = dark_sec, b = dark_sec, c = dark_sec, x = dark_sec, y = dark_sec, z = dark_sec },
      inactive = {
        a = { fg = fg_dim, bg = bg },
        b = { fg = fg_dim, bg = bg },
        c = { fg = fg_dim, bg = bg },
        x = { fg = fg_dim, bg = bg },
        y = { fg = fg_dim, bg = bg },
        z = { fg = fg_dim, bg = bg },
      },
    }

    -- ── Helpers ───────────────────────────────────────────────────────────

    local function emoji_location()
      return "📍 " .. vim.fn.line "." .. ":" .. vim.fn.virtcol "."
    end

    -- ── Terminal extension ────────────────────────────────────────────────

    local function term_shell()
      local bufname = vim.api.nvim_buf_get_name(0)
      local shell = bufname:match "/([^/]+)$" or vim.fn.fnamemodify(vim.o.shell, ":t")
      return " " .. shell
    end

    local function term_cwd()
      local cwd = vim.fn.getcwd()
      local parts = vim.split(cwd, "/", { trimempty = true })
      if #parts >= 2 then
        return "  " .. parts[#parts - 1] .. "/" .. parts[#parts]
      end
      return "  " .. (parts[#parts] or cwd)
    end

    local terminal_extension = {
      filetypes = { "jeffterm" },
      sections = {
        lualine_a = {
          {
            "mode",
            color = function()
              return { fg = palette.base, bg = accent() }
            end,
            -- padding = { left = 1, right = 1 },
            separator = { left = "", right = "" },
          },
        },
        lualine_b = {},
        lualine_c = {
          { term_shell, color = { fg = fg, bg = bg } },
          { term_cwd, color = { fg = fg_dim, bg = bg } },
        },
        lualine_x = {},
        lualine_y = { { "progress", color = { fg = fg_dim, bg = bg } } },
        lualine_z = { { emoji_location, color = { fg = fg, bg = bg } } },
      },
    }

    -- ── AI extensions ─────────────────────────────────────────────────────
    -- With a fully dark theme, the bar is already correct — we just need
    -- the name pill + arrow in the accent color. No filler hacks needed.

    local function ai_extension(filetypes, label, pill_color)
      return {
        filetypes = filetypes,
        sections = {
          lualine_a = {
            {
              function()
                return label
              end,
              color = { fg = palette.base, bg = pill_color },
              -- padding = { left = 1, right = 1 },
              separator = { left = "", right = "" },
            },
            -- {
            --   -- Static arrow: fg = pill color, bg = bar bg
            --   function()
            --     return ""
            --   end,
            --   color = { fg = pill_color, bg = bg },
            --   padding = 0,
            -- },
          },
          lualine_b = {},
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        },
      }
    end

    local claude_extension = ai_extension({ "claudecode_term" }, " Claude Code", palette.mauve)
    local opencode_extension = ai_extension({ "opencode_term" }, " OpenCode", palette.sapphire)

    -- ── Main setup ────────────────────────────────────────────────────────

    lualine.setup {
      options = {
        theme = flat_theme,
        section_separators = "", -- no section separators by default
        -- section_separators = { left = "", right = "" },
        component_separators = "", -- no component separators either
        globalstatus = false,
      },

      sections = {
        lualine_a = {
          {
            "mode",
            separator = { left = "", right = "" },
            color = function()
              return { fg = palette.base, bg = accent() }
            end,
            -- padding = { left = 1, right = 1 },
          },
        },

        lualine_b = {
          {
            "branch",
            icon = "",
            color = { fg = palette.blue, bg = bg },
          },
        },

        lualine_c = {
          {
            "filename",
            path = 1,
            color = { fg = fg, bg = bg },
          },
        },

        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { fg = palette.peach, bg = bg },
          },
          {
            "filetype",
            icon_only = false,
            color = { fg = fg, bg = bg },
          },
        },

        lualine_y = {
          { "progress", color = { fg = fg_dim, bg = bg } },
        },

        lualine_z = {
          { emoji_location, color = { fg = fg, bg = bg } },
        },
      },

      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          { "filename", path = 1, color = { fg = fg_dim, bg = bg } },
        },
        lualine_x = {
          { "location", color = { fg = fg_dim, bg = bg } },
        },
        lualine_y = {},
        lualine_z = {},
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

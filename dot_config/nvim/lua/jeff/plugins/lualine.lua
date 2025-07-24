return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require "lualine"
    local custom_catppuccin = require "lualine.themes.catppuccin"
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

        -- Set all sections to match (solid bar)
        for _, section in ipairs { "a", "b", "c", "x", "y", "z" } do
          mode[section] = { fg = fg, bg = bg }
        end
      end
    end

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
            icon = "",
            color = function()
              local theme = require "lualine.themes.catppuccin"
              local mode = vim.fn.mode()
              local fg = (theme[mode] and theme[mode].a.fg) or theme.normal.a.fg
              return { fg = fg }
            end,
          },
        },
        -- lualine_c = {
        --   function()
        --     return "%="
        --   end,
        --   {
        --     function()
        --       local filepath = vim.fn.expand "%:."
        --       local dir = vim.fn.fnamemodify(filepath, ":h")
        --       return dir ~= "." and dir or ""
        --     end,
        --     color = function()
        --       local theme = require "lualine.themes.catppuccin"
        --       local mode = vim.fn.mode()
        --       local fg = (theme[mode] and theme[mode].a.fg) or theme.normal.a.fg
        --       return { fg = fg }
        --     end,
        --   },
        -- },
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
              local theme = require "lualine.themes.catppuccin"
              local mode = vim.fn.mode()
              local fg = (theme[mode] and theme[mode].a.fg) or theme.normal.a.fg
              return { fg = fg }
            end,
          },
          {
            "filetype",
            icon_only = false,
            color = function()
              local theme = require "lualine.themes.catppuccin"
              local mode = vim.fn.mode()
              local fg = (theme[mode] and theme[mode].a.fg) or theme.normal.a.fg
              return { fg = fg }
            end,
          },
        },
        lualine_y = { "progress" },
        lualine_z = { emoji_location },
      },
    }
  end,
}

return {
  "echasnovski/mini.nvim",
  version = "*",

  config = function()
    require("mini.ai").setup()
    require("mini.bracketed").setup()
    require("mini.comment").setup()
    require("mini.completion").setup()
    require("mini.icons").setup()
    require("mini.operators").setup()
    require("mini.pairs").setup()
    require("mini.sessions").setup()
    require("mini.snippets").setup()
    require("mini.surround").setup()
  end,
}

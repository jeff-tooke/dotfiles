-- Disable unused Neovim language providers for a cleaner setup
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

require "jeff.core"
require "jeff.lazy"
require "jeff.custom"

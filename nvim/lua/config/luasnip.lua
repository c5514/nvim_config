local ls = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()
--require('luasnip-latex-snippets').setup()
require('luasnip.loaders.from_lua').lazy_load({paths ="~/.config/nvim/lua/snippets/" })
ls.config.set_config {
 history = true,
 updateevents = 'TextChanged,TextChangedI',
 enable_autosnippets = true
}
local M = {}
function M.expand_or_jump()
 if ls.expand_or_jumpable() then
    ls.expand_or_jump()
 end 
end 
function M.jump_next()
 if ls.jumpable(1) then
   ls.jump(1)
 end 
end 
function M.jump_prev()
 if ls.jumpable(-1) then
  ls.jump(-1)
  end 
end 
function M.change_choice()
 if ls.choice_active() then
   ls.change_choice(1)
  end 
end 
function M.refresh_snippets()
 ls.cleanup()
  require("luasnip.loaders.from_lua").lazy_load({ paths = "~/.config/nvim/lua/snippets/" })
end 
local set = vim.keymap.set 
local mode = {'i', 's'}
local normal = {'n'}
set(mode, '<c-i>', M.expand_or_jump)
set(mode, '<c-n>', M.jump_prev)
set(mode, '<c-l>', M.change_choice)
set(mode, '<,r>', M.refresh_snippets)

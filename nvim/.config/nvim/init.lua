-- Set space as your leader key (must happen BEFORE lazy loads)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable basic line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Bootstrap the plugin manager
require("config.lazy")

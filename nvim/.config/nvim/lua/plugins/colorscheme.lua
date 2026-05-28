local STATE_FILE = vim.fn.expand("~/.config/theme-state")

local function read_state()
  local f = io.open(STATE_FILE, "r")
  if not f then return "dark" end
  local s = (f:read("*l") or "dark"):gsub("%s+", "")
  f:close()
  return (s == "light") and "light" or "dark"
end

local function apply(state)
  vim.o.background = state
  local scheme = (state == "light") and "catppuccin-latte" or "catppuccin-mocha"
  pcall(vim.cmd.colorscheme, scheme)
end

local function watch()
  local handle = (vim.uv or vim.loop).new_fs_event()
  if not handle then return end
  handle:start(STATE_FILE, {}, function(err)
    if err then return end
    vim.schedule(function() apply(read_state()) end)
    -- fs_event fires once on some filesystems; re-arm.
    handle:stop()
    vim.defer_fn(watch, 100)
  end)
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = { transparent_background = true, integrations = { telescope = true, treesitter = true } },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      apply(read_state())
      watch()
    end,
  },
}

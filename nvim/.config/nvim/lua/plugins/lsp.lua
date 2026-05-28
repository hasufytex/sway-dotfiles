return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    -- Set up Mason to download language servers
    require("mason").setup()
    
    -- Bridge Mason with the newer lspconfig structures
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls" }, 
    })

    -- Diagnostic display tweaks
    vim.diagnostic.config({ virtual_text = true, signcolumn = true })

    -- Run this function whenever an LSP connects to a file
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local buf = args.buf
        local opts = { buffer = buf }

        -- Essential LSP Hotkeys
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)      -- Go to definition
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)            -- Show documentation
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)  -- Rename variable across file
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts) -- Trigger code actions
      end,
    })

    -- Fetch autocomplete capabilities
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- NEW NATIVE API: Use vim.lsp.config instead of require('lspconfig')
    if vim.lsp.config then
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
      })
      vim.lsp.config("pyright", { capabilities = capabilities })
      vim.lsp.enable("pyright")
    else
      -- Fallback for backwards compatibility if needed
      require("lspconfig").lua_ls.setup({
        capabilities = capabilities,
      })
    end
    
    -- Note: If you add more LSPs via :Mason later (like pyright, ts_ls),
    -- you can just add them right below like this:
    -- vim.lsp.config("pyright", { capabilities = capabilities })
  end,
}

return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/nvim-cmp",
  },
  config = function()
    -- Configuration specifically for the Go language server (gopls)
    require("lspconfig").gopls.setup({
      cmd = { "gopls", "serve" },
      settings = {
        gopls = {
          analyses = {
            unusedparams = true,
          },
          staticcheck = true,
          usePlaceholders = true,
          completeUnimported = true,
        },
      },
      capabilities = require("cmp_nvim_lsp").default_capabilities(),
    })
  end,
}

-- C++ specific settings
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true
vim.opt_local.cindent = true
vim.opt_local.smartindent = true

-- Set compiler for C++
vim.opt_local.makeprg = "g++ -std=c++17 -Wall -Wextra -O2 -o %:r %"

-- Format on save (optional)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.cpp",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

return {
  "fatih/vim-go",
  ft = "go",
  build = ":GoUpdateBinaries",
  config = function()
    -- Disable all linters as we use null-ls
    vim.g.go_diagnostics_enabled = 0
    vim.g.go_metalinter_enabled = 0

    -- Use gopls
    vim.g.go_gopls_enabled = 1
    
    -- Status line types/signatures
    vim.g.go_auto_type_info = 1

    -- Run gofmt/goimports when saving
    vim.g.go_fmt_command = "goimports"

    -- Syntax highlighting
    vim.g.go_highlight_types = 1
    vim.g.go_highlight_fields = 1
    vim.g.go_highlight_functions = 1
    vim.g.go_highlight_function_calls = 1
    vim.g.go_highlight_operators = 1
    vim.g.go_highlight_extra_types = 1
  end,
}

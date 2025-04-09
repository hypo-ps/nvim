-- Enable filetype detection and plugins
vim.cmd('filetype plugin indent on')
-- Enable auto-indentation
vim.opt.autoindent = true
vim.opt.smartindent = true
-- Set indentation based on filetype
vim.cmd('autocmd FileType * set formatoptions+=r')
-- Preserve indentation when entering insert mode on empty lines
vim.cmd([[
function! IndentEmptyLines()
    let l:line = getline('.')
    if l:line =~ '^\s*$'
        let l:prev_line = getline(line('.') - 1)
        let l:indent = matchstr(l:prev_line, '^\s*')
        call setline('.', l:indent)
    endif
endfunction

" Apply the indentation when entering insert mode
autocmd InsertEnter * call IndentEmptyLines()
]])

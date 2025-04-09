return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    local npairs = require("nvim-autopairs")
    npairs.setup({
      check_ts = true,                  -- Use treesitter if available
      ts_config = {
        lua = {'string'},               -- Don't add pairs in lua string treesitter nodes
        javascript = {'template_string'},
      },
      disable_filetype = { "TelescopePrompt" },
      fast_wrap = {
        map = "<M-e>",                  -- Alt+e to wrap with brackets
        chars = { "{", "[", "(", '"', "'" },
        pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
        end_key = "$",
        keys = "qwertyuiopzxcvbnmasdfghjkl",
        check_comma = true,
        highlight = "Search",
        highlight_grey = "Comment"
      },
    })

    -- If you want integration with treesitter
    local cmp_autopairs = require('nvim-autopairs.completion.cmp')
    local cmp_status_ok, cmp = pcall(require, 'cmp')
    if cmp_status_ok then
      cmp.event:on(
        'confirm_done',
        cmp_autopairs.on_confirm_done()
      )
    end
  end,
}

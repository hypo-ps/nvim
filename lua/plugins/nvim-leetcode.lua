return {
  "kawre/leetcode.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    -- Keep authentication section minimal to use interactive login
    lang = "cpp",
    cn = {
      enabled = false,  -- Change this boolean to a table with 'enabled' field
    },
    -- Tell the plugin to use browser auth
    cookie = {
      browser = true, -- This should trigger browser-based authentication
    },

    -- Directly specify the endpoint with browser enabled
    endpoint = {
      browser = true,
    },
     -- Enable browser-based authentication
    description = {
      position = "left",
      width = "40%",
    },

    storage = {
      path = vim.fn.stdpath("data") .. "/leetcode/",
      organize_by_id = false,
    },

    console = {
      open_on_runcode = true,
      size = "20%",
      direction = "horizontal",
    },

    -- Additional user-friendly settings
    keys = {
      toggle = { "q", "<Esc>" }, -- keybindings to close windows
      confirm = { "<CR>" },      -- keybindings to confirm
    },

    image_support = false,  -- set to true if your terminal supports image display
  },
}

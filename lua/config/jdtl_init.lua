-- Setup our JDTLS server any time we open up a java file
vim.api.nvim_create_autocmd("FileType", {
    pattern = "java",
    callback = function()
        require("config.jdtls").setup_jdtls()
    end,
    group = vim.api.nvim_create_augroup("jdtls_lsp", { clear = true }),
    desc = "Setup JDTLS for Java files"
})

-- Add keymaps to manually initialize the Java environment
vim.keymap.set("n", "<leader>js", function()
    vim.cmd("SetupBazelProject")
end, { desc = "Setup Java Bazel Project" })

-- Add helpful status message
vim.api.nvim_create_user_command("JavaStatus", function()
    local clients = vim.lsp.get_active_clients({ name = "jdtls" })
    if next(clients) == nil then
        vim.notify("JDTLS is not running", vim.log.levels.WARN)
    else
        vim.notify("JDTLS is active", vim.log.levels.INFO)

        -- Check if we're in a Bazel project
        local root_markers = { 'WORKSPACE', 'WORKSPACE.bazel' }
        local root_dir = require('jdtls.setup').find_root(root_markers)
        if root_dir and root_dir ~= "" then
            vim.notify("Detected Bazel project at: " .. root_dir, vim.log.levels.INFO)
        end
    end
end, {})

-- Add a keymap to check Java status
vim.keymap.set("n", "<leader>ji", "<cmd>JavaStatus<cr>", { desc = "Java Status" })

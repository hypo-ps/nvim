local M = {}

function M.setup()
    -- Setup our JDTLS server any time we open up a java file
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = function()
            -- Check if we're in a Java project
            local root_markers = {'.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', 'WORKSPACE', 'WORKSPACE.bazel'}
            local root_dir = require('jdtls.setup').find_root(root_markers)

            if root_dir == "" then
                vim.notify("Not in a Java project, skipping JDTLS setup", vim.log.levels.WARN)
                return
            end

            -- Try to start JDTLS
            local status, err = pcall(function()
                require('config.jdtls').setup_jdtls()
            end)

            if not status then
                vim.notify("Error starting JDTLS: " .. tostring(err), vim.log.levels.ERROR)
            end
        end,
        group = vim.api.nvim_create_augroup("jdtls_setup", { clear = true }),
        desc = "Setup JDTLS for Java files"
    })

    -- Create Bazel-specific commands that are available outside Java buffers
    vim.api.nvim_create_user_command("BazelBuildAll", function()
        vim.notify("Building all targets with Bazel...", vim.log.levels.INFO)
        vim.fn.jobstart("bazel build //...", {
            on_exit = function(_, code)
                if code == 0 then
                    vim.notify("Bazel build completed successfully", vim.log.levels.INFO)
                    -- Force JDTLS to reload after build
                    vim.cmd("LspRestart jdtls")
                else
                    vim.notify("Bazel build failed with code " .. code, vim.log.levels.ERROR)
                end
            end,
            stdout_buffered = true,
            on_stdout = function(_, data)
                if data then
                    vim.notify(table.concat(data, "\n"), vim.log.levels.INFO)
                end
            end,
            on_stderr = function(_, data)
                if data then
                    vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
                end
            end,
        })
    end, {})

    -- Create a specialized command to regenerate Eclipse project files for Bazel
    vim.api.nvim_create_user_command("SetupBazelProject", function()
        -- 1. Build the project
        vim.notify("Setting up Bazel project...", vim.log.levels.INFO)
        vim.fn.jobstart("bazel build //...", {
            on_exit = function(_, code)
                if code == 0 then
                    -- 2. Try to generate Eclipse project files if bazel-eclipse plugin is available
                    vim.fn.jobstart("bazel build //... --aspects=@bazel_eclipse//:aspects.bzl%eclipse_aspect --output_groups=eclipse 2>/dev/null || echo 'Eclipse aspect not available'", {
                        on_exit = function(_, aspect_code)
                            if aspect_code == 0 then
                                vim.notify("Eclipse project files generated", vim.log.levels.INFO)
                            else
                                vim.notify("Eclipse aspect not available - using basic configuration", vim.log.levels.WARN)

                                -- Create basic .classpath file with common Java paths
                                local root_dir = require('jdtls.setup').find_root({'.git', 'WORKSPACE', 'WORKSPACE.bazel'})
                                if root_dir ~= "" then
                                    local classpath_content = [[<?xml version="1.0" encoding="UTF-8"?>
<classpath>
    <classpathentry kind="src" path="src/main/java"/>
    <classpathentry kind="src" path="src/test/java"/>
    <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>
    <classpathentry kind="output" path="bin"/>
</classpath>]]

                                    local f = io.open(root_dir .. "/.classpath", "w")
                                    if f then
                                        f:write(classpath_content)
                                        f:close()
                                        vim.notify("Created basic .classpath file", vim.log.levels.INFO)
                                    end
                                end
                            end

                            -- 3. Restart the LSP server to pick up changes
                            vim.cmd("LspRestart jdtls")
                            vim.notify("JDTLS restarted - project setup complete", vim.log.levels.INFO)
                        end
                    })
                else
                    vim.notify("Bazel build failed with code " .. code, vim.log.levels.ERROR)
                end
            end
        })
    end, {})

    -- Add a keymap to quickly access the setup command
    vim.keymap.set('n', '<leader>js', "<Cmd>SetupBazelProject<CR>", { desc = "[J]ava [S]etup Bazel Project" })
end

return M

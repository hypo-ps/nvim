local function get_jdtls()
    -- Get the Mason Registry to gain access to downloaded binaries
    local mason_registry = require("mason-registry")
    -- Find the JDTLS package in the Mason Regsitry
    local jdtls = mason_registry.get_package("jdtls")
    -- Find the full path to the directory where Mason has downloaded the JDTLS binaries
    local jdtls_path = jdtls:get_install_path()
    -- Obtain the path to the jar which runs the language server
    local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
    -- Declare which operating system we are using
    local SYSTEM = "mac"
    -- Obtain the path to configuration files for your specific operating system
    local config = jdtls_path .. "/config_" .. SYSTEM
    -- Obtain the path to the Lombok jar
    local lombok = jdtls_path .. "/lombok.jar"
    return launcher, config, lombok
end

local function get_bundles()
    -- Get the Mason Registry to gain access to downloaded binaries
    local mason_registry = require("mason-registry")
    -- Find the Java Debug Adapter package in the Mason Registry
    local java_debug = mason_registry.get_package("java-debug-adapter")
    -- Obtain the full path to the directory where Mason has downloaded the Java Debug Adapter binaries
    local java_debug_path = java_debug:get_install_path()

    local bundles = {
        vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", 1)
    }

    -- Find the Java Test package in the Mason Registry
    local java_test = mason_registry.get_package("java-test")
    -- Obtain the full path to the directory where Mason has downloaded the Java Test binaries
    local java_test_path = java_test:get_install_path()
    -- Add all of the Jars for running tests in debug mode to the bundles list
    vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar", 1), "\n"))

    return bundles
end

local function get_workspace()
    -- Get the home directory of your operating system
    local home = os.getenv("HOME") or os.getenv("USERPROFILE")
    -- Declare a directory where you would like to store project information
    local workspace_path = home .. "/code/workspace/"
    -- Determine the project name
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
    -- Create the workspace directory by concatenating the designated workspace path and the project name
    local workspace_dir = workspace_path .. project_name

    -- Ensure workspace directory exists
    if vim.fn.isdirectory(workspace_dir) == 0 then
        vim.fn.mkdir(workspace_dir, "p")
    end

    return workspace_dir
end

local function configure_bazel_project(settings, root_dir)
    -- Detect if this is a Bazel project
    if vim.fn.filereadable(root_dir .. "/WORKSPACE") == 1 or vim.fn.filereadable(root_dir .. "/WORKSPACE.bazel") == 1 then
        vim.notify("Bazel project detected, configuring JDTLS accordingly", vim.log.levels.INFO)

        -- Minimal Bazel configuration
        settings.java.configuration.updateBuildConfiguration = "disabled"

        -- Skip complex scanning and detection
        vim.notify("Applied minimal Bazel configuration", vim.log.levels.INFO)
    end

    return settings
end

local function setup_bazel_extra_commands()
    -- Add Bazel-specific commands
    vim.api.nvim_create_user_command("BazelBuild", function()
        vim.notify("Building with Bazel...", vim.log.levels.INFO)
        vim.fn.jobstart("bazel build //...", {
            on_exit = function(_, code)
                if code == 0 then
                    vim.notify("Bazel build completed successfully", vim.log.levels.INFO)
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

    vim.api.nvim_create_user_command("BazelTest", function()
        vim.notify("Testing with Bazel...", vim.log.levels.INFO)
        vim.fn.jobstart("bazel test //...", {
            on_exit = function(_, code)
                if code == 0 then
                    vim.notify("Bazel tests passed", vim.log.levels.INFO)
                else
                    vim.notify("Bazel tests failed with code " .. code, vim.log.levels.ERROR)
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

    -- Command to generate Eclipse project files for Bazel
    vim.api.nvim_create_user_command("BazelGenerateEclipseFiles", function()
        vim.notify("Generating Eclipse project files for Bazel...", vim.log.levels.INFO)
        -- Adjust this command based on your Bazel plugin setup
        vim.fn.jobstart("bazel build //... --aspects=@bazel_eclipse//:aspects.bzl%eclipse_aspect --output_groups=eclipse", {
            on_exit = function(_, code)
                if code == 0 then
                    vim.notify("Eclipse project files generated successfully", vim.log.levels.INFO)
                    -- Reload JDTLS to pick up the new configuration
                    vim.cmd("LspRestart jdtls")
                else
                    vim.notify("Failed to generate Eclipse project files, code: " .. code, vim.log.levels.ERROR)
                end
            end,
        })
    end, {})
end

local function java_keymaps()
    -- Allow yourself to run JdtCompile as a Vim command
    vim.cmd("command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_compile JdtCompile lua require('jdtls').compile(<f-args>)")
    -- Allow yourself/register to run JdtUpdateConfig as a Vim command
    vim.cmd("command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()")
    -- Allow yourself/register to run JdtBytecode as a Vim command
    vim.cmd("command! -buffer JdtBytecode lua require('jdtls').javap()")
    -- Allow yourself/register to run JdtShell as a Vim command
    vim.cmd("command! -buffer JdtJshell lua require('jdtls').jshell()")

    -- Set a Vim motion to <Space> + <Shift>J + o to organize imports in normal mode
    vim.keymap.set('n', '<leader>Jo', "<Cmd> lua require('jdtls').organize_imports()<CR>", { desc = "[J]ava [O]rganize Imports", buffer = true })
    -- Set a Vim motion to <Space> + <Shift>J + v to extract the code under the cursor to a variable
    vim.keymap.set('n', '<leader>Jv', "<Cmd> lua require('jdtls').extract_variable()<CR>", { desc = "[J]ava Extract [V]ariable", buffer = true })
    -- Set a Vim motion to <Space> + <Shift>J + v to extract the code selected in visual mode to a variable
    vim.keymap.set('v', '<leader>Jv', "<Esc><Cmd> lua require('jdtls').extract_variable(true)<CR>", { desc = "[J]ava Extract [V]ariable", buffer = true })
    -- Set a Vim motion to <Space> + <Shift>J + <Shift>C to extract the code under the cursor to a static variable
    vim.keymap.set('n', '<leader>JC', "<Cmd> lua require('jdtls').extract_constant()<CR>", { desc = "[J]ava Extract [C]onstant", buffer = true })
    -- Set a Vim motion to <Space> + <Shift>J + <Shift>C to extract the code selected in visual mode to a static variable
    vim.keymap.set('v', '<leader>JC', "<Esc><Cmd> lua require('jdtls').extract_constant(true)<CR>", { desc = "[J]ava Extract [C]onstant", buffer = true })
    -- Set a Vim motion to <Space> + <Shift>J + t to run the test method currently under the cursor
    vim.keymap.set('n', '<leader>Jt', "<Cmd> lua require('jdtls').test_nearest_method()<CR>", { desc = "[J]ava [T]est Method", buffer = true })
    -- Set a Vim motion to <Space> + <Shift>J + t to run the test method that is currently selected in visual mode
    vim.keymap.set('v', '<leader>Jt', "<Esc><Cmd> lua require('jdtls').test_nearest_method(true)<CR>", { desc = "[J]ava [T]est Method", buffer = true })
    -- Set a Vim motion to <Space> + <Shift>J + <Shift>T to run an entire test suite (class)
    vim.keymap.set('n', '<leader>JT', "<Cmd> lua require('jdtls').test_class()<CR>", { desc = "[J]ava [T]est Class", buffer = true })
    -- Set a vim motion to <Space> + <Shift>J + u to update the project configuration
    vim.keymap.set('n', '<leader>Ju', "<Cmd> JdtUpdateConfig<CR>", { desc = "[J]ava [U]pdate Config", buffer = true })

    -- Bazel-specific keymaps
    vim.keymap.set('n', '<leader>Jb', "<Cmd> BazelBuild<CR>", { desc = "[J]ava [B]azel Build", buffer = true })
    vim.keymap.set('n', '<leader>JB', "<Cmd> BazelTest<CR>", { desc = "[J]ava [B]azel Test", buffer = true })
    vim.keymap.set('n', '<leader>Je', "<Cmd> BazelGenerateEclipseFiles<CR>", { desc = "[J]ava Generate [E]clipse Files", buffer = true })

    -- Add a keymap to force refresh the Java language server
    vim.keymap.set('n', '<leader>Jr', function()
        vim.notify("Restarting Java language server...", vim.log.levels.INFO)
        vim.cmd("LspRestart jdtls")
    end, { desc = "[J]ava LSP [R]estart", buffer = true })

    -- Add a keymap to manually resolve project dependencies
    vim.keymap.set('n', '<leader>Jd', function()
        vim.lsp.buf.execute_command({command = "java.project.refreshDependencies", arguments = {}})
    end, { desc = "[J]ava Refresh [D]ependencies", buffer = true })
end

local function setup_jdtls()
    -- Get access to the jdtls plugin and all of its functionality
    local jdtls = require("jdtls")

    -- Get the paths to the jdtls jar, operating specific configuration directory, and lombok jar
    local launcher, os_config, lombok = get_jdtls()
    -- Get the path you specified to hold project information
    local workspace_dir = get_workspace()
    -- Get the bundles list with the jars to the debug adapter, and testing adapters
    local bundles = get_bundles()

    -- Determine the root directory of the project by looking for these specific markers
    local root_markers = {'.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', 'WORKSPACE', 'WORKSPACE.bazel'}
    local root_dir = jdtls.setup.find_root(root_markers)

    if root_dir == "" then
        vim.notify("Could not find Java project root", vim.log.levels.WARN)
        return
    end

    -- Tell our JDTLS language features it is capable of
    local capabilities = {
        workspace = {
            configuration = true
        },
        textDocument = {
            completion = {
                completionItem = {
                    snippetSupport = true
                }
            }
        }
    }

    local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()

    for k, v in pairs(lsp_capabilities) do
        capabilities[k] = v
    end

    -- Get the default extended client capabilities of the JDTLS language server
    local extendedClientCapabilities = jdtls.extendedClientCapabilities
    -- Modify one property called resolveAdditionalTextEditsSupport and set it to true
    extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

    -- Add more capabilities for better code intelligence
    extendedClientCapabilities.classFileContentsSupport = true

    -- Set the command that starts the JDTLS language server jar
    local cmd = {
        '/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home/bin/java', -- Use 'java' on non-Mac platforms
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-Xmx4g', -- Increased memory for larger projects
        '--add-modules=ALL-SYSTEM',
        '--add-opens', 'java.base/java.util=ALL-UNNAMED',
        '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
        '-javaagent:' .. lombok,
        '-jar', launcher,
        '-configuration', os_config,
        '-data', workspace_dir,
    }

    -- Configure settings in the JDTLS server
    local settings = {
        java = {
            -- Enable code formatting
            format = {
                enabled = true,
                -- Use the Google Style guide for code formatting
                settings = {
                    url = vim.fn.stdpath("config") .. "/lang_servers/intellij-java-google-style.xml",
                    profile = "GoogleStyle"
                }
            },
            -- Enable downloading archives from eclipse automatically
            eclipse = {
                downloadSource = true
            },
            -- Enable downloading archives from maven automatically
            maven = {
                downloadSources = true
            },
            -- Enable method signature help
            signatureHelp = {
                enabled = true
            },
            -- Use the fernflower decompiler when using the javap command to decompile byte code back to java code
            contentProvider = {
                preferred = "fernflower"
            },
            -- Setup automatic package import organization on file save
            saveActions = {
                organizeImports = true
            },
            -- Customize completion options
            completion = {
                -- Enable parameter hints
                importOrder = {"java", "jakarta", "javax", "com", "org"},
                -- When using an unimported static method, how should the LSP rank possible places to import the static method from
                favoriteStaticMembers = {
                    "org.hamcrest.MatcherAssert.assertThat",
                    "org.hamcrest.Matchers.*",
                    "org.hamcrest.CoreMatchers.*",
                    "org.junit.jupiter.api.Assertions.*",
                    "java.util.Objects.requireNonNull",
                    "java.util.Objects.requireNonNullElse",
                    "org.mockito.Mockito.*",
                },
                -- Try not to suggest imports from these packages in the code action window
                filteredTypes = {
                    "com.sun.*",
                    "io.micrometer.shaded.*",
                    "java.awt.*",
                    "jdk.*",
                    "sun.*",
                },
                -- Set the order in which the language server should organize imports
                importOrder = {
                    "java",
                    "jakarta",
                    "javax",
                    "com",
                    "org",
                }
            },
            sources = {
                -- How many classes from a specific package should be imported before automatic imports combine them all into a single import
                organizeImports = {
                    starThreshold = 5, -- More reasonable threshold
                    staticStarThreshold = 3
                }
            },
            -- How should different pieces of code be generated?
            codeGeneration = {
                -- When generating toString use a json format
                toString = {
                    template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
                },
                -- When generating hashCode and equals methods use the java 7 objects method
                hashCodeEquals = {
                    useJava7Objects = true
                },
                -- When generating code use code blocks
                useBlocks = true
            },
            -- If changes to the project will require the developer to update the projects configuration advise the developer before accepting the change
            configuration = {
                updateBuildConfiguration = "interactive",
                runtimes = {
                    {
                        name = "JavaSE-17",
                        path = "/Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk/Contents/Home",
                        default = true
                    }
                }
            },
            -- enable code lens in the lsp
            referencesCodeLens = {
                enabled = true
            },
            implementationsCodeLens = {
                enabled = true
            },
            -- enable inlay hints for parameter names
            inlayHints = {
                parameterNames = {
                    enabled = "all"
                }
            },
            -- Configure dependency resolution
            project = {
                referencedLibraries = {
                    "lib/**/*.jar",
                    "bazel-bin/**/*.jar"  -- Include Bazel output directories
                }
            },
            -- Allow recommending dependencies
            dependency = {
                packageSearch = {
                    enabled = true
                }
            },
            -- Recognize source directories from Bazel build
            autobuild = {
                enabled = false  -- Disable autobuild for Bazel projects
            },
            -- Add import settings for better package resolution
            imports = {
                gradle = {
                    enabled = false,  -- Disable for Bazel projects
                },
                maven = {
                    enabled = false,  -- Disable for Bazel projects
                },
                exclusions = {
                    "**/node_modules/**",
                    "**/.metadata/**",
                    "**/archetype-resources/**",
                    "**/META-INF/maven/**",
                    "**/.git/**",
                },
            },
            -- Configure references search to be more aggressive
            references = {
                includeDecompiledSources = true,
            }
        },
        redhat = {
            telemetry = {
                enabled = false,
            },
        },
    }

    -- Apply Bazel-specific configuration if this is a Bazel project
    settings = configure_bazel_project(settings, root_dir)

    -- Create a table called init_options to pass the bundles with debug and testing jar, along with the extended client capabilities to the start or attach function of JDTLS
    local init_options = {
        bundles = bundles,
        extendedClientCapabilities = extendedClientCapabilities
    }

    -- Function that will be ran once the language server is attached
    local on_attach = function(client, bufnr)
        -- Map the Java specific key mappings once the server is attached
        java_keymaps()

        -- Set up Bazel-specific commands
        setup_bazel_extra_commands()

        -- Setup the java debug adapter of the JDTLS server
        require('jdtls.dap').setup_dap()

        -- Refresh source paths based on Bazel directory structure
--        vim.lsp.buf.execute_command({command = "java.project.updateSourcePaths", arguments = {}})

        -- Find the main method(s) of the application so the debug adapter can successfully start up the application
        require('jdtls.dap').setup_dap_main_class_configs()

        -- Enable jdtls commands to be used in Neovim
        require('jdtls.setup').add_commands()

        -- Refresh the codelens
        vim.lsp.codelens.refresh()

        -- Setup a function that automatically runs every time a java file is saved to refresh the code lens
        vim.api.nvim_create_autocmd("BufWritePost", {
            pattern = { "*.java" },
            callback = function()
                local _, _ = pcall(vim.lsp.codelens.refresh)
            end
        })

        -- Add a notification to show the project is ready
        vim.notify("Java language server attached. Full functionality may take a moment as the server indexes your project.", vim.log.levels.INFO)

        -- Add autocmd to refresh imports on save
        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = { "*.java" },
            callback = function()
                local _, _ = pcall(require('jdtls').organize_imports)
            end
        })
    end

    -- Create the configuration table for the start or attach function
    local config = {
        cmd = cmd,
        root_dir = root_dir,
        settings = settings,
        capabilities = capabilities,
        init_options = init_options,
        on_attach = on_attach,
        flags = {
            allow_incremental_sync = true,
        },
    }

    -- Start the JDTLS server
    require('jdtls').start_or_attach(config)

    -- Output notification about the setup
    vim.notify("JDTLS started for Java project at: " .. root_dir, vim.log.levels.INFO)
end

return {
    setup_jdtls = setup_jdtls,
}

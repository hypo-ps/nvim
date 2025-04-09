# My Neovim Configuration

This repository contains my personal Neovim configuration for a modern, fast, and powerful editing experience.

## Features

- 🚀 Fast startup time with lazy-loading plugins
- 🎨 Modern UI with a clean and minimal theme
- 💡 Intelligent code completion with LSP integration
- 🔍 Fuzzy finding for files, buffers, and text
- 📦 Git integration for seamless version control
- 🧩 Custom keybindings for improved workflow
- 🛠️ Language-specific configurations

## Prerequisites

- Neovim >= 0.8.0
- Git
- [Optional] Node.js (for LSP features)
- [Optional] A [Nerd Font](https://www.nerdfonts.com/) for icons

## Installation

1. Backup your existing Neovim configuration (if any):

```bash
mv ~/.config/nvim ~/.config/nvim.bak
```

2. Clone this repository:

```bash
git clone https://github.com/your-username/nvim-config.git ~/.config/nvim
```

3. Start Neovim:

```bash
nvim
```

The configuration will automatically install the plugin manager and all plugins on the first run.

## Structure

```
~/.config/nvim/
├── init.lua                 # Main entry point
├── lua/
│   ├── core/               # Core configuration
│   │   ├── keymaps.lua     # Key mappings
│   │   ├── options.lua     # Neovim options
│   │   └── autocmds.lua    # Autocommands
│   ├── plugins/            # Plugin configurations
│   │   ├── lsp/            # LSP configurations
│   │   └── ...
│   └── utils/              # Utility functions
└── README.md               # This file
```

## Key Bindings

| Key Binding | Mode | Description |
|-------------|------|-------------|
| `<Space>`   | N    | Leader key  |
| `<Leader>ff`| N    | Find files  |
| `<Leader>fg`| N    | Live grep   |
| `<Leader>e` | N    | File explorer |
| `<C-h/j/k/l>` | N  | Window navigation |
| `gd`        | N    | Go to definition |
| `K`         | N    | Show hover information |

See `lua/core/keymaps.lua` for more key bindings.

## Plugins

This configuration uses [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager. Some of the included plugins are:

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Fuzzy finder
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - LSP configuration
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) - Completion plugin
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - Syntax highlighting
- [which-key.nvim](https://github.com/folke/which-key.nvim) - Displays keybindings

## Customization

Feel free to customize this configuration to suit your needs:

- Modify `lua/core/options.lua` to change Neovim settings
- Add or remove plugins in `lua/plugins/init.lua`
- Adjust keybindings in `lua/core/keymaps.lua`

## Inspiration and Credits

This configuration was inspired by:

- [LazyVim](https://github.com/LazyVim/LazyVim)
- [NvChad](https://github.com/NvChad/NvChad)
- [LunarVim](https://github.com/LunarVim/LunarVim)

## License

MIT

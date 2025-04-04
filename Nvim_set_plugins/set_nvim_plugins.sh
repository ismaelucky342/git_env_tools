#!/bin/bash

# Neovim configuration directories
NVIM_CONFIG="$HOME/.config/nvim"
NVIM_DATA="$HOME/.local/share/nvim"
NVIM_BIN="$HOME/.local/bin"
GIT_ENV_TOOLS="$HOME/git_env_tools"
WALLPAPER="$GIT_ENV_TOOLS/neon_city.jpg"

echo "🚀 Installing Neovim Plugins and Advanced Configuration..."

# Create directory structure
mkdir -p "$NVIM_CONFIG" "$NVIM_DATA" "$NVIM_BIN"

# Install Lazy.nvim if not present
if [ ! -d "$NVIM_DATA/lazy/lazy.nvim" ]; then
    echo "📥 Downloading Lazy.nvim..."
    git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$NVIM_DATA/lazy/lazy.nvim"
fi

# Copy wallpaper to Neovim config directory
if [ -f "$WALLPAPER" ]; then
    echo "🖼  Setting up wallpaper for Neovim..."
    cp "$WALLPAPER" "$NVIM_CONFIG/neon_city.jpg"
else
    echo "⚠️  Warning: Wallpaper not found in $WALLPAPER"
fi

# Detect terminal and apply background image settings
if [ -n "$KITTY_WINDOW_ID" ]; then
    echo "🌆 Configuring Kitty with wallpaper..."
    echo "background_image $NVIM_CONFIG/neon_city.jpg" >> ~/.config/kitty/kitty.conf
elif [ "$TERM_PROGRAM" == "WezTerm" ]; then
    echo "🌆 Configuring WezTerm with wallpaper..."
    cat > ~/.wezterm.lua <<EOF
return {
  window_background_image = "$NVIM_CONFIG/neon_city.jpg",
  window_background_opacity = 0.85,
}
EOF
fi

# Install ImageMagick locally (no sudo)
MAGICK_DIR="$HOME/.local/ImageMagick"
if [ ! -d "$MAGICK_DIR" ]; then
    echo "📷 Installing ImageMagick locally..."
    mkdir -p "$MAGICK_DIR"
    curl -L https://imagemagick.org/archive/releases/ImageMagick-7.1.1-24.tar.gz | tar -xz -C "$MAGICK_DIR" --strip-components=1
    cd "$MAGICK_DIR" || exit
    ./configure --prefix="$MAGICK_DIR" --with-modules
    make -j$(nproc) && make install
    cd - || exit
    echo "export PATH=\"$MAGICK_DIR/bin:\$PATH\"" >> ~/.bashrc
    echo "export LD_LIBRARY_PATH=\"$MAGICK_DIR/lib:\$LD_LIBRARY_PATH\"" >> ~/.bashrc
    export PATH="$MAGICK_DIR/bin:$PATH"
    export LD_LIBRARY_PATH="$MAGICK_DIR/lib:$LD_LIBRARY_PATH"
fi

# Install LuaRocks locally (no sudo)
LUAROCKS_DIR="$HOME/.local/luarocks"
if [ ! -d "$LUAROCKS_DIR" ]; then
    echo "🔨 Installing LuaRocks locally..."
    mkdir -p "$LUAROCKS_DIR"
    curl -L http://luarocks.github.io/luarocks/releases/luarocks-3.9.1.tar.gz | tar -xz -C "$LUAROCKS_DIR" --strip-components=1
    cd "$LUAROCKS_DIR" || exit
    ./configure --prefix="$LUAROCKS_DIR" --with-lua-include=/usr/include/lua5.1
    make -j$(nproc) && make install
    cd - || exit
    echo "export PATH=\"$LUAROCKS_DIR/bin:\$PATH\"" >> ~/.bashrc
    export PATH="$LUAROCKS_DIR/bin:$PATH"
fi

# Install lua-magick (without sudo)
echo "🔮 Installing lua-magick..."
"$LUAROCKS_DIR/bin/luarocks" install magick --tree="$HOME/.local"

# Install image.nvim dependencies
echo "🖼 Installing magick.nvim dependencies..."
"$LUAROCKS_DIR/bin/luarocks" install magick

# Create init.lua configuration file
echo "📝 Creating configuration in $NVIM_CONFIG/init.lua..."
cat > "$NVIM_CONFIG/init.lua" << 'EOF'
-- Load Lazy.nvim
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")

-- Install Plugins
require("lazy").setup({
    -- 🎨 UI & Colors
    { "folke/tokyonight.nvim", lazy = false, priority = 1000, config = function()
        vim.cmd("colorscheme tokyonight")
    end },

    -- 📌 Plugin Manager
    { "folke/lazy.nvim" },

    -- 🚀 LSP and Autocompletion
    { "neovim/nvim-lspconfig" },
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    { "hrsh7th/nvim-cmp", dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" } },
    { "github/copilot.vim" },

    -- 🔎 Fuzzy Finder & File Explorer
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" }, config = function()
        require("nvim-tree").setup({
            view = { width = 35 },
            renderer = { icons = { show = { file = true, folder = true, git = true } } },
            update_focused_file = { enable = true },
        })
        vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
    end },

    -- 🛠 Debugging & Terminal
    { "mfussenegger/nvim-dap" },
    { "akinsho/toggleterm.nvim" },

    -- 🎨 Enhanced UI
    { "nvim-lualine/lualine.nvim" },
    { "romgrk/barbar.nvim" },
    { "lukas-reineke/indent-blankline.nvim" },
    { "lewis6991/gitsigns.nvim" },
    { "folke/trouble.nvim" },

    -- 📝 Notes and Sessions
    { "nvim-neorg/neorg" },
    { "Shatur/neovim-session-manager" },

    -- 💪 Workflow
    { "windwp/nvim-autopairs" },
    { "numToStr/Comment.nvim" },
    { "tpope/vim-surround" },
    { "tpope/vim-fugitive" },
    { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },

    -- 🔄 Session Management
    { "rmagatti/auto-session" },

    -- 🖼 Wallpaper Plugin
    { "3rd/image.nvim", dependencies = { "nvim-lua/plenary.nvim" }, config = function()
        require("image").setup()
    end }
})

-- Display wallpaper inside Neovim
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if vim.fn.executable("kitty") == 1 or os.getenv("TERM_PROGRAM") == "WezTerm" then
            vim.cmd("Image " .. vim.fn.stdpath('config') .. "/neon_city.jpg")
        end
    end
})

-- Keybindings
vim.api.nvim_set_keymap("n", "<C-p>", ":Telescope find_files<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-t>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
EOF

echo "✅ Neovim configured with all required plugins"
echo "📝 Open Neovim and run ':Lazy sync' to install the plugins"

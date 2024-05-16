local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
vim.o.number = true
vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.textwidth = 120
vim.o.cc = "120"
vim.o.foldmethod="expr"
vim.o.foldexpr="nvim_treesitter#foldexpr()"
vim.o.foldenable = false
vim.g.mapleader = " "
local function map(mode, shortcut, command)
  vim.api.nvim_set_keymap(mode, shortcut, command, { noremap = true, silent = true })
end

local function nmap(shortcut, command)
  map('n', shortcut, command)
end

local function imap(shortcut, command)
  map('i', shortcut, command)
end

imap("jk", "<esc>")
nmap("<leader>sw", ":lua require'telescope.builtin'.lsp_workspace_symbols{}<CR>")
nmap("<leader>sf", ":lua require'telescope.builtin'.find_files{}<CR>")
nmap("<leader>ff", ":lua require'telescope'.extensions.file_browser.file_browser({ path = '%:p:h' })<CR>")
nmap("<leader>gd",":lua vim.lsp.buf.definition()<CR>")
nmap("<leader>gD",":lua vim.lsp.buf.declaration()<CR>")
nmap("<leader>gt",":FloatermNew cd %:p:h && lazygit<CR>") -- Stupid hack, hope I can find something better
nmap("K", ":lua vim.lsp.buf.hover()<CR>")
require("lazy").setup({
  "neovim/nvim-lspconfig",
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-vsnip",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-buffer",
  "hrsh7th/vim-vsnip",
  "hrsh7th/cmp-nvim-lsp-signature-help",
  "voldikss/vim-floaterm",
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.6',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope-fzf-native.nvim'}
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    'nvim-lualine/lualine.nvim',
    lazy = false,
    dependencies = { 'nvim-tree/nvim-web-devicons' }
  },
  {
    "lervag/vimtex",
    lazy = false,     -- we don't want to lazy load VimTeX
    init = function()
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate"
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
  },
})

require'lspconfig'.rust_analyzer.setup {
  settings = {
    ['rust-analyzer'] = {
      check = {
        command = "clippy";
      },
      diagnostics = {
        enable = true;
      }
    }
  }
}
require"lualine".setup({
  options = {
    theme = 'tokyonight'
  },
  sections = {
    lualine_c = {
      {
        'filename',
        file_status = true, -- displays file status (readonly status, modified status)
        path = 1 -- 0 = just filename, 1 = relative path, 2 = absolute path
      }
    }
  },

})

require'lspconfig'.lua_ls.setup {
  on_init = function(client)
    local path = client.workspace_folders[1].name
    if vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc') then
      return
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT'
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME
          -- Depending on the usage, you might want to add additional paths here.
          -- "${3rd}/luv/library"
          -- "${3rd}/busted/library",
        }
        -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
        -- library = vim.api.nvim_get_runtime_file("", true)
      }
    })
  end,
  settings = {
    Lua = {
      diagnostics = {
        globals = {"vim"}
      }
    }
  }
}

local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  preselect = cmp.PreselectMode.None,
  completion = {
    completeopt = 'menu,menuone,noselect,noinsert'
  },
  mapping = {
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<CR>"] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, {"i", "s"}),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, {"i", "s"}),
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
  },
  sources =  {
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
    { name = 'path' },
    { name = 'buffer' },
    { name = 'nvim_lsp_signature_help' },
  },
})
require'lspconfig'.clangd.setup{}
require'lspconfig'.ocamllsp.setup{}
require'lspconfig'.pyright.setup{}
require'lspconfig'.ocamllsp.setup{}

require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn", -- set to `false` to disable one of the mappings
      node_incremental = "grn",
      scope_incremental = "grc",
      node_decremental = "grm",
    },
  },
}

vim.cmd[[colorscheme tokyonight]]
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end
})

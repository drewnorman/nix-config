{ pkgs, ... }:

let
  treesitterWithGrammars = pkgs.vimPlugins.nvim-treesitter.withPlugins (parsers: with parsers; [
    bash
    c
    css
    diff
    html
    java
    javascript
    json
    lua
    markdown
    markdown_inline
    nix
    php
    query
    regex
    rust
    tsx
    twig
    typescript
    vim
    vimdoc
    vue
    xml
    yaml
  ]);
in

{
  home = {
    username = "drew";
    homeDirectory = "/home/drew";
    stateVersion = "25.11";
    packages = with pkgs; [
      bat
      eza
      fd
      fzf
      jq
      lazygit
      nodejs
      ripgrep
      php
      phpPackages.composer
      yazi
      zoxide
    ];
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = false;
    withRuby = false;

    extraPackages = with pkgs; [
      emmet-language-server
      fzf
      intelephense
      jdt-language-server
      lua-language-server
      nixd
      phpPackages.php-cs-fixer
      prettier
      prettierd
      ripgrep
      stylua
      tailwindcss-language-server
      typescript-language-server
      vscode-langservers-extracted
      zsh
    ];

    plugins = with pkgs.vimPlugins; [
      aerial-nvim
      blink-cmp
      conform-nvim
      fidget-nvim
      friendly-snippets
      fzf-lua
      gitsigns-nvim
      indent-blankline-nvim
      lazygit-nvim
      leap-nvim
      lualine-nvim
      luasnip
      neoscroll-nvim
      nvim-lspconfig
      nvim-surround
      nvim-treesitter-textobjects
      overseer-nvim
      papercolor-theme-slim
      plenary-nvim
      treesitterWithGrammars
      vim-abolish
      ferret
      vim-tmux-navigator
      which-key-nvim
      yazi-nvim
    ];
  };

  xdg.configFile."nvim".source = ./nvim;

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user.name = "Drew Norman";
      user.email = "drewnorman739@gmail.com";
      init.defaultBranch = "master";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      e = "nvim";
      ls = "eza";
      lsa = "eza -la";
      q = "exit";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}

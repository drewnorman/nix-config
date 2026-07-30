{
  pkgs,
  inputs,
  ...
}:
let
  diffGrammar = pkgs.vimPlugins.nvim-treesitter.builtGrammars.diff.overrideAttrs {
    version = "0.0.0+rev=1a24d30";
    src = pkgs.fetchurl {
      url = "https://github.com/tree-sitter-grammars/tree-sitter-diff/archive/1a24d30d9b2b0bbf8420e229164462f410fb3ad0.tar.gz";
      hash = "sha256-15ukDQ3/cwvlfbVep2prndMImrGliUxEy7JoDnzRQUM=";
    };
  };

  treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
    grammars: with grammars; [
      bash
      c
      css
      diffGrammar
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
    ]
  );
in
{
  imports = [ inputs.nix-wrapper-modules.homeModules.neovim ];

  wrappers.neovim = {
    enable = true;

    settings.config_directory = "/home/drew/code/personal/nix-config/home/drew/nvim";

    settings.aliases = [
      "vi"
      "vim"
    ];

    runtimePkgs = with pkgs; [
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
      yazi
    ];

    specs.treesitter = {
      data = treesitter;
      before = [ "INIT_MAIN" ];
    };

    specs.treesitter-textobjects = {
      data = pkgs.vimPlugins.nvim-treesitter-textobjects;
      pluginDeps = false;
      before = [ "INIT_MAIN" ];
    };

    info.lsp = {
      emmet = true;
      intelephense = true;
      jdtls = true;
      lua = true;
      nix = true;
      tailwind = true;
      typescript = true;
      vscode = true;
    };
  };

  home.sessionVariables.EDITOR = "nvim";

  home.persistence."/persist".directories = [ ".local/share/nvim" ];
}

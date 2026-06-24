{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  treesitterGrammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; {
    bash = bash;
    c = c;
    css = css;
    diff = diff;
    html = html;
    java = java;
    javascript = javascript;
    json = json;
    lua = lua;
    markdown = markdown;
    markdown_inline = markdown_inline;
    nix = nix;
    php = php;
    query = query;
    regex = regex;
    rust = rust;
    tsx = tsx;
    twig = twig;
    typescript = typescript;
    vim = vim;
    vimdoc = vimdoc;
    vue = vue;
    xml = xml;
    yaml = yaml;
  };

  treesitterRuntime = pkgs.runCommand "nvim-treesitter-runtime" { } ''
    mkdir -p "$out/parser"

    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (lang: grammar: ''
        ln -s ${grammar}/parser "$out/parser/${lang}.so"
      '') treesitterGrammars
    )}
  '';
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

    specs.treesitter-grammars = {
      collateGrammars = false;
      data = treesitterRuntime;
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

{ pkgs, inputs, ... }:
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
      gcc
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
    ];

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

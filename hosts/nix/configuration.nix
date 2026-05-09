{ modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
  ];

  networking.hostName = "lab-nix";
  networking.domain = "lab.adre.me";
  networking.nameservers = [
    "192.168.1.210"
    "1.1.1.1"
  ];

  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.mutableUsers = false;
  users.users.drew = {
    isNormalUser = true;
    description = "Drew Norman";
    extraGroups = [
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIH+qwzVnHyU19AY9TKxZD2iCU9/DPSbGq1HIPByr8Hc drew@x1c-g9"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    neovim
    ripgrep
    tmux
    wget
  ];

  programs.zsh.enable = true;
  users.users.drew.shell = pkgs.zsh;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  system.stateVersion = "25.11";
}

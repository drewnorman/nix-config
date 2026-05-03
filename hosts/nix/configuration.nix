{ modulesPath, pkgs, ... }:

{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  networking.hostName = "lab-nix";
  networking.domain = "lab.adre.me";
  networking.useDHCP = false;
  networking.useNetworkd = true;
  networking.nameservers = [
    "172.16.0.210"
    "1.1.1.1"
  ];
  systemd.network.enable = true;
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "en*";
    networkConfig = {
      DHCP = "no";
      IPv6AcceptRA = false;
    };
    address = [ "172.16.0.240/24" ];
    gateway = [ "172.16.0.1" ];
    dns = [
      "172.16.0.210"
      "1.1.1.1"
    ];
    domains = [ "lab.adre.me" ];
  };

  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "console=ttyS0" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  services.qemuGuest.enable = true;
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

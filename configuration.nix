# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    "${inputs.impermanence}/nixos.nix"
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Disable hibernation.
  boot.kernelParams = [ "nohibernate" ];

  # Support ZFS.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;

  # Define the host ID.
  networking.hostId = "67ed658f";

  # Define the hostname.
  networking.hostName = "xps15-9550";

  # Enable iwd.
  networking.wireless.iwd.enable = true;

  # Set your time zone.
  time.timeZone = "US/Mountain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    keyMap = "us";
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable OpenGL.
  hardware.opengl.enable = true;

  # Allow other users to access bind-mounted directories.
  programs.fuse.userAllowOther = true;

  # Enable ZSH.
  programs.zsh = {
    enable = true;
    shellInit = ''
	zsh-newuser-install () {}
    '';
  };

  # Make users immutable.
  users.mutableUsers = false;

  # Set root password.
  users.users.root.passwordFile = "/persist/secrets/root/system-pass";

  # Define a user account.
  users.users.drew = {
    description = "Drew Norman";
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "audio" "video"
      "systemd-journal"
    ];
    shell = pkgs.zsh;
    uid = 1000;
    passwordFile = "/persist/secrets/drew/system-pass";
  };

  # Define packages installed in system profile.
  environment.systemPackages = with pkgs; [

    # Build Essentials
    binutils
    gcc
    gnumake
    pkgconfig
    python

    # Utilities
    gitAndTools.gitFull
    neovim
    python3
    tree
    unzip
    wget
    zip

    # Nix
    nix-diff
    nix-du
    nix-top
  ];

  # Persist system configurations.
  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"
      "/var/log"
      "/secrets"
      "/etc/iwd"
      "/var/lib/iwd"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  # Activate home-manager environment if necessary
  environment.loginShellInit = ''
    [ -d "$HOME/.nix-profile" ] || /nix/var/nix/profiles/per-user/$USER/home-manager/activate &> /dev/null
  '';

  # Nix
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings = {
      trusted-users = [ "root" "@wheel" ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}


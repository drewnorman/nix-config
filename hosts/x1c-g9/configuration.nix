{ pkgs, ... }:

{
  networking.hostName = "x1c-g9";
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
      luks.devices.crypted.device = "/dev/disk/by-uuid/208b84fc-d18e-42a6-9ede-489f50421821";
    };

    kernelModules = [
      "kvm-intel"
    ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C33D-CFED";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  nixpkgs.config.allowUnfree = true;
  hardware = {
    acpilight.enable = true;
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
    firmware = with pkgs; [
      sof-firmware
    ];
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
  };

  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    blueman.enable = true;
    fstrim.enable = true;
    fwupd.enable = true;
    libinput.enable = true;
    tailscale.enable = true;
    udisks2.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd sway";
        user = "greeter";
      };
    };
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    sudo.wheelNeedsPassword = false;
  };

  users = {
    mutableUsers = false;
    users.drew = {
      isNormalUser = true;
      description = "Drew Norman";
      extraGroups = [
        "networkmanager"
        "podman"
        "video"
        "wheel"
      ];
      hashedPasswordFile = "/persist/secrets/users/drew/password";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIH+qwzVnHyU19AY9TKxZD2iCU9/DPSbGq1HIPByr8Hc drew@x1c-g9"
      ];
      shell = pkgs.zsh;
    };
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  programs = {
    firefox.enable = true;
    git.enable = true;
    nm-applet.enable = true;
    ssh.startAgent = true;
    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        alacritty
        gammastep
        grim
        mako
        slurp
        swayidle
        swaylock-effects
        waybar
        wl-clipboard
        wofi
        xwayland
      ];
    };
    zsh.enable = true;
  };

  fonts.packages = with pkgs; [
    font-awesome
    inconsolata
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

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
    _7zz
    alsa-utils
    aria2
    autoconf
    automake
    bind
    binutils
    bison
    bridge-utils
    curl
    dnsmasq
    efibootmgr
    exif
    fakeroot
    file
    flex
    fuse-overlayfs
    gcc
    git-lfs
    google-chrome
    google-cloud-sdk
    graphicsmagick
    htop
    httpie
    intel-gpu-tools
    iptables
    lftp
    m4
    gnumake
    man-db
    mitmproxy
    mold
    mpv
    ncdu
    neovim
    nmap
    netcat-openbsd
    openssh
    opentofu
    pass
    patch
    perl
    pkg-config
    podman-compose
    python3Packages.openpyxl
    python3Packages.websocket-client
    ripgrep
    rsync
    sops
    sshpass
    strace
    texinfo
    tmux
    traceroute
    tree-sitter
    unzip
    vulkan-tools
    wget
    whois
    wimlib
    zip
    zsa-udev-rules
  ];

  services.udev.packages = with pkgs; [
    zsa-udev-rules
  ];

  system.stateVersion = "25.11";
}

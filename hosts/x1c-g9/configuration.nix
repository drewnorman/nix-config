{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "x1c-g9";
  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = true;
      timeout = 5;
    };
  };

  nixpkgs.config.allowUnfree = true;

  networking = {
    useNetworkd = true;
    wireless.iwd.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
    };
  };

  programs.ssh.systemd-ssh-proxy.enable = false;

  services = {
    openssh.enable = false;

    fstrim.enable = true;
    fwupd.enable = true;
    libinput.enable = true;
    resolved.enable = true;
    tailscale.enable = true;
    thermald.enable = true;
    tlp.enable = true;
    udisks2.enable = true;

    logind.settings.Login = {
      HandleLidSwitchDocked = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    getty = {
      autologinUser = "drew";
      autologinOnce = true;
    };
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    sudo.wheelNeedsPassword = true;
  };

  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

  users = {
    mutableUsers = false;
    users.drew = {
      isNormalUser = true;
      description = "Drew Norman";
      uid = 1000;
      linger = true;
      extraGroups = [
        "podman"
        "video"
        "wheel"
      ];
      hashedPasswordFile = "/persist/secrets/users/drew/password";
      shell = pkgs.fish;
    };
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  systemd.network = {
    enable = true;
    networks."25-wireless" = {
      matchConfig.Type = "wlan";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
    };
  };

  programs = {
    chromium = {
      enable = true;
      extraOpts = {
        ClearBrowsingDataOnExitList = [ ];
        DefaultCookiesSetting = 1;
      };
    };
    dconf.enable = true;
    firefox.enable = true;
    git.enable = true;
    nh = {
      enable = true;
      flake = "/home/drew/code/personal/nix-config";
    };
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        glibc
        stdenv.cc.cc
      ];
    };
    ssh.startAgent = true;
    sway = {
      enable = true;
      extraOptions = [ "--unsupported-gpu" ];
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        alacritty
        gammastep
        grim
        mako
        xdg-desktop-portal-wlr
        slurp
        swayidle
        swaylock-effects
        wl-clipboard
        wofi
        xwayland
      ];
    };
    fish.enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
    config = {
      common = {
        default = [
          "wlr"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Settings" = "gtk";
      };
      sway."org.freedesktop.impl.portal.Settings" = "gtk";
    };
  };

  systemd.coredump.settings.Coredump = {
    Storage = "none";
    ProcessSizeMax = 0;
  };

  fonts.packages = with pkgs; [
    font-awesome
    inconsolata
    nerd-fonts.symbols-only
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
    google-cloud-sdk
    graphicsmagick
    htop
    httpie
    intel-gpu-tools
    iptables
    just
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

{ pkgs, ... }:

{
  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = false;
  };

  programs.virt-manager.enable = true;

  users.users.drew.extraGroups = [
    "kvm"
    "libvirtd"
  ];

  environment.systemPackages = with pkgs; [
    passt
    signify
    virt-viewer
    xz
  ];

  home-manager.users.drew = {
    home = {
      persistence."/persist".directories = [
        ".config/libvirt"
        ".local/share/images"
        ".local/share/libvirt"
      ];
      sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///session";
    };

    # Whonix's current templates use unprivileged, per-user libvirt. Override
    # the system-wide virt-manager default installed by the NixOS module.
    dconf.settings."org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///session" ];
      uris = [ "qemu:///session" ];
    };

    # Avoid an unprivileged qemu:///session startup failure when libvirt tries
    # to raise process resource limits.
    xdg.configFile."libvirt/qemu.conf".text = ''
      max_core = 0
      max_processes = 0
      max_files = 0
    '';
  };
}

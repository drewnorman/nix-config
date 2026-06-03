{ lib, ... }:

{
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  boot.initrd.systemd.services.rollback-btrfs-root = {
    description = "Rollback BTRFS root subvolume to blank snapshot";
    wantedBy = [ "initrd.target" ];
    requires = [ "dev-vg-nixos.device" ];
    after = [ "dev-vg-nixos.device" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /mnt
      mount -o subvol=/ /dev/vg/nixos /mnt

      if [ -e /mnt/root-blank ]; then
        if [ -e /mnt/root ]; then
          btrfs subvolume list -o /mnt/root | cut -f9 -d' ' | while read -r subvolume; do
            btrfs subvolume delete "/mnt/$subvolume"
          done
          btrfs subvolume delete /mnt/root
        fi

        btrfs subvolume snapshot /mnt/root-blank /mnt/root
      else
        echo "Missing BTRFS blank snapshot: root-blank" >&2
      fi

      umount /mnt
    '';
  };

  fileSystems."/" = {
    device = "/dev/vg/nixos";
    fsType = "btrfs";
    options = [
      "subvol=root"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/vg/nixos";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/persist" = {
    device = "/dev/vg/nixos";
    fsType = "btrfs";
    neededForBoot = true;
    options = [
      "subvol=persist"
      "compress=zstd"
      "noatime"
    ];
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/bluetooth"
      "/var/lib/containers"
      "/var/lib/fprint"
      "/var/lib/iwd"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/tailscale"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}

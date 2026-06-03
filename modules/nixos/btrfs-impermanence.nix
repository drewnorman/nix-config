{ pkgs, ... }:

{
  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.initrd.systemd.storePaths = with pkgs; [
    btrfs-progs
    coreutils
    gawk
    gnused
    util-linux
  ];

  boot.initrd.systemd.services.rollback-btrfs-root = {
    description = "Rollback BTRFS root subvolume to blank snapshot";
    wantedBy = [ "initrd.target" ];
    requires = [ "dev-vg-nixos.device" ];
    after = [ "dev-vg-nixos.device" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail

      mkdir -p /mnt
      trap 'umount /mnt 2>/dev/null || true' EXIT

      mount -o subvol=/ /dev/vg/nixos /mnt

      if ! btrfs subvolume show /mnt/root-blank >/dev/null 2>&1; then
        echo "Missing BTRFS blank snapshot: root-blank" >&2
        exit 1
      fi

      if [ -e /mnt/root ]; then
        btrfs subvolume list -o /mnt/root \
          | cut -f9- -d' ' \
          | awk '{ path = $0; depth = gsub("/", "/", path); print depth, length($0), $0 }' \
          | sort -rn -k1,1 -k2,2 \
          | cut -d' ' -f3- \
          | while read -r subvolume; do
            btrfs subvolume delete "/mnt/$subvolume"
          done
        btrfs subvolume delete /mnt/root
      fi

      btrfs subvolume snapshot /mnt/root-blank /mnt/root
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

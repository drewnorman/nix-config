# Installation

## ThinkPad X1 Carbon Gen 9 (`x1c-g9`)

This flake output targets the laptop replacing the current Arch install.
It assumes the encrypted LUKS, LVM, BTRFS, and swap layout has already been
created, with opt-in persistence for both system state and Drew's home.

### Storage preparation

Follow [docs/x1c-g9-storage-migration.md](docs/x1c-g9-storage-migration.md)
before installing. The NixOS configuration expects `/dev/vg/nixos` to contain
the BTRFS subvolumes and `/dev/vg/nixos-swap` to be available for swap and
hibernate resume.

### Mounts

```sh
cryptsetup open /dev/disk/by-uuid/208b84fc-d18e-42a6-9ede-489f50421821 crypted
vgchange -ay vg

mount -o subvol=root,compress=zstd,noatime /dev/vg/nixos /mnt
mkdir -p /mnt/{boot,nix,persist}
mount -o subvol=nix,compress=zstd,noatime /dev/vg/nixos /mnt/nix
mount -o subvol=persist,compress=zstd,noatime /dev/vg/nixos /mnt/persist
mount /dev/disk/by-uuid/C33D-CFED /mnt/boot
swapon /dev/vg/nixos-swap
```

Create the persisted password file before install:

```sh
mkdir -p /mnt/persist/secrets/users/drew
mkpasswd -m sha-512 > /mnt/persist/secrets/users/drew/password
chmod 600 /mnt/persist/secrets/users/drew/password
install -d -m 700 -o 1000 -g 100 /mnt/persist/home/drew
```

### Install

```sh
nixos-install --flake .#x1c-g9
```

### First boot checks

After the first successful NixOS boot, confirm the shared ESP still has the
expected boot entries and that hibernate can resume from the NixOS swap LV:

```sh
sudo efibootmgr -v
bootctl status
free -h
swapon --show
systemctl hibernate
```

The configured swap LV is `34G`. Increase it before relying on hibernation if
installed RAM exceeds that capacity.

### Rebuilding

```sh
sudo nixos-rebuild switch --flake .#x1c-g9
```

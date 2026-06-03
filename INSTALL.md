# Installation

## ThinkPad X1 Carbon Gen 9 (`x1c-g9`)

This flake output targets the laptop replacing the current Arch install.
It assumes encrypted BTRFS with opt-in persistence for both system state and
Drew's home.

### BTRFS layout

After opening the LUKS device as `crypted`, create these subvolumes:

```sh
mount /dev/mapper/crypted /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/persist
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
umount /mnt
```

`root-blank` is the blank root snapshot. On each boot, initrd deletes the
mutable `root` subvolume and recreates it from `root-blank`.

### Mounts

```sh
mount -o subvol=root,compress=zstd,noatime /dev/mapper/crypted /mnt
mkdir -p /mnt/{boot,nix,persist}
mount -o subvol=nix,compress=zstd,noatime /dev/mapper/crypted /mnt/nix
mount -o subvol=persist,compress=zstd,noatime /dev/mapper/crypted /mnt/persist
mount /dev/disk/by-uuid/C33D-CFED /mnt/boot
```

Create the persisted password file before install:

```sh
mkdir -p /mnt/persist/secrets/users/drew
mkpasswd -m sha-512 > /mnt/persist/secrets/users/drew/password
chmod 600 /mnt/persist/secrets/users/drew/password
```

### Install

```sh
nixos-install --flake .#x1c-g9
```

### Rebuilding

```sh
sudo nixos-rebuild switch --flake .#x1c-g9
```

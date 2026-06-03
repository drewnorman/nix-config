# X1C Gen 9 Storage Migration

This procedure is destructive. Back up important data before starting, verify
every device path, and do not run commands until the existing Arch LUKS, LVM,
and filesystem layout is understood.

The target layout keeps Arch and NixOS inside the existing LUKS container with
volume group `vg`:

- Arch root LV: `40G`
- Arch home LV: `40G`
- NixOS swap LV: `34G`
- NixOS BTRFS LV: remaining free space

## Boot And Unlock

Boot from trusted live media with `cryptsetup`, `lvm2`, and `btrfs-progs`
available.

```sh
cryptsetup open /dev/disk/by-uuid/208b84fc-d18e-42a6-9ede-489f50421821 crypted
vgchange -ay vg
```

Inspect the current state before changing anything:

```sh
lsblk -f
lvs -a -o +devices
blkid
```

## Check Filesystems

Unmount any mounted Arch filesystems, then check them before shrinking.
Adjust filesystem types if the current Arch layout differs.

```sh
e2fsck -f /dev/vg/root
e2fsck -f /dev/vg/home
```

## Shrink Arch

Shrink Arch root and home to `40G` each. These commands assume ext4.

```sh
lvreduce --resizefs --size 40G /dev/vg/root

lvreduce --resizefs --size 40G /dev/vg/home
```

## Reuse Arch Nix LV

The existing Arch `vg/nix` LV is disposable for this migration. Remove it if it
exists and is not mounted.

```sh
lvremove /dev/vg/nix
```

## Create NixOS Volumes

Create a dedicated hibernate-sized swap LV, then allocate the remaining free
space to the NixOS BTRFS LV.

```sh
lvcreate --name nixos-swap --size 34G vg
lvcreate --name nixos --extents 100%FREE vg
```

Format the new volumes:

```sh
mkswap /dev/vg/nixos-swap
mkfs.btrfs -f /dev/vg/nixos
```

## Create BTRFS Subvolumes

```sh
mount /dev/vg/nixos /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/persist
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
umount /mnt
```

`root-blank` is the blank readonly root snapshot. On each boot, initrd deletes
the mutable `root` subvolume and recreates it from `root-blank`.

## Verify

```sh
lsblk -f
lvs -a -o +devices
blkid /dev/vg/nixos /dev/vg/nixos-swap
swapon /dev/vg/nixos-swap
swapon --show
swapoff /dev/vg/nixos-swap

mount /dev/vg/nixos /mnt
btrfs subvolume list /mnt
umount /mnt
```

# X1C Gen 9 Storage Migration

This procedure is destructive. Back up important data before starting, verify
every device path, and do not run commands until the existing Arch LUKS, LVM,
and filesystem layout is understood.

The target layout keeps Arch and NixOS inside the existing LUKS container with
volume group `vg`. Arch stays small and self-contained as a fallback install;
NixOS gets the remaining SSD space:

- Arch root LV: `40G`
- Arch home LV: `40G`
- Arch swap LV: `8G`
- NixOS swap LV: `16G`
- NixOS BTRFS LV: remaining free space

The NixOS swap LV is ordinary low-priority disk swap. NixOS uses ZRAM first for
normal memory pressure, then falls back to `/dev/vg/nixos-swap` if needed.

The assumed current LVM setup is an existing Arch install under the same LUKS
container, with `/dev/vg/root`, `/dev/vg/home`, and possibly `/dev/vg/nix` and
`/dev/vg/swap`. Confirm the actual LV names before running any resize or remove
commands.

## Boot And Unlock

Boot from trusted live media with `cryptsetup`, `lvm2`, and `btrfs-progs`
available.

Record the current EFI state before installing NixOS. NixOS uses
systemd-boot on the shared ESP, so keep the existing Arch EFI entry and boot
order handy in case firmware defaults change after installation.

```sh
efibootmgr -v
find /boot/efi /boot -maxdepth 3 -type f 2>/dev/null
```

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

Keep Arch's swap separate from NixOS swap. If `/dev/vg/swap` already exists,
turn it off, resize it to `8G`, and recreate the swap signature.

```sh
swapoff /dev/vg/swap || true
lvresize --size 8G /dev/vg/swap
mkswap /dev/vg/swap
```

If Arch does not already have a swap LV:

```sh
lvcreate --name swap --size 8G vg
mkswap /dev/vg/swap
```

After changing Arch swap, verify Arch's `/etc/fstab` points at the current swap
UUID or stable LV path.

## Reuse Arch Nix LV

The existing Arch `vg/nix` LV is disposable for this migration. Remove it if it
exists, is not mounted, and Arch no longer expects it at boot.

Check Arch's filesystem configuration before removing the LV:

```sh
mount /dev/vg/root /mnt
grep -R "vg/nix\|/nix" /mnt/etc/fstab /mnt/etc/systemd/system 2>/dev/null || true
umount /mnt
```

If Arch still references `/dev/vg/nix` or `/nix`, remove that mount or mark it
`nofail` before continuing. Rebuild Arch's initramfs if the old LV appears in
initramfs hooks or boot-critical mount configuration.

```sh
lvremove /dev/vg/nix
```

## Create NixOS Volumes

Create a dedicated NixOS disk swap LV, then allocate the remaining free space to
the NixOS BTRFS LV.

```sh
lvcreate --name nixos-swap --size 16G vg
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
install -d -m 700 -o 1000 -g 100 /mnt/persist/home/drew
umount /mnt
```

`root-blank` is the blank readonly root snapshot. On each boot, initrd deletes
the mutable `root` subvolume and recreates it from `root-blank`.
Home Manager persists Drew's opt-in home state under `/persist/home/drew`; UID
`1000` and GID `100` match the NixOS user declaration.

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

## Arch Boot Fallback

Keep Arch bootable through its existing EFI entry unless you intentionally move
it under the NixOS-managed systemd-boot menu. After NixOS installation, verify
both entries are still present:

```sh
efibootmgr -v
bootctl status
```

If firmware now defaults to NixOS, use `efibootmgr` or the firmware boot menu to
select the original Arch entry. If you want Arch in the systemd-boot menu later,
add a checked-in loader entry only after confirming Arch's kernel/initramfs paths
on the ESP and its root kernel arguments.

## Swap Check

```sh
free -h
zramctl
swapon --show
```

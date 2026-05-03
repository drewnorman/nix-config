# Installation

## Proxmox Lab Nix Host

The `nix` flake output is designed for the homelab Proxmox VM named `lab-nix`.
The homelab OpenTofu configuration reserves `172.16.0.240` and AdGuard resolves
`nix.lab.adre.me` directly to that address.

Configure the Proxmox VM with OVMF/UEFI firmware so `systemd-boot` can install
cleanly. From a NixOS installer booted inside the Proxmox VM, partition and
format the target disk with the labels expected by `hosts/nix/configuration.nix`:

```sh
sudo -i
DISK=/dev/sda # adjust if the VM disk appears as /dev/vda or /dev/nvme0n1
sgdisk --zap-all "$DISK"
sgdisk -n 1:1MiB:+1GiB -t 1:EF00 -c 1:boot "$DISK"
sgdisk -n 2:0:0 -t 2:8300 -c 2:nixos "$DISK"
mkfs.vfat -n boot "${DISK}1"
mkfs.ext4 -L nixos "${DISK}2"
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```

Then clone this repository and install:

```sh
mkdir -p /mnt/etc
git clone https://github.com/drewnorman/nix-config /mnt/etc/nixos
cd /mnt/etc/nixos
nixos-install --flake .#nix
```

After reboot:

```sh
ssh drew@nix.lab.adre.me
```

The following steps prepare a new system for NixOS. The current setup aims for
opt-in system and user state, where anything not explicitly persisted is not
available following reboot.

Both `/` and `/home` exist in tmpfs filesystems while `/nix` and `/persist` are
data sets in an encrypted ZFS pool. The `/persist` data set is used to create 
bind mounts for persisted data to the ephermeral `/` and `/home` directories.

With opt-in system and user state, we can easily keep clutter to a minimum.

## Preparing the Disk

First let's get the disk ready for installation.

### Creating a Bootable USB
1. Download the NixOS minimal installer image.
2. Use `dd` to write the image to a USB.

### Updating Firmware Settings
1. Ensure USB is listed before the SSD/HDD in the boot order.
2. Disable safe boot.
3. Enable UEFI mode.

### Booting the Installer
1. Boot from the USB.
2. Start an interactive root shell with `sudo -i`.
3. Connect to the internet with `wpa_supplicant`:
  ```
  systemctl start wpa_supplicant
  wpa_cli
  add_network
  set_network 0 ssid "myhomenetwork"
  set_network 0 psk "mypassword"
  set_network 0 key_mgmt WPA-PSK
  enable_network 0
  quit
  ```
4. Test internet connection with `ping google.com`.

### Partitioning the Disk
1. Identify SSD/HDD with `lsblk`.
2. Wipe all partitions with `sgdisk --zap-all /dev/nvme0n1`.
3. List devices' by-id aliases with `ls -l /dev/disk/by-id/`.
4. Define disk ID with `DISK_ID="$(ls /dev/disk/by-id/ | grep 'nvme-eui')"`.
5. Check the value for disk ID with `echo $DISK_ID`.
6. Define disk with `DISK=/dev/disk/by-id/$DISK_ID`.
7. Create partitions, adjusting the swap size as necessary:
  ```
  sgdisk -n 0:0:+1GiB -t 0:EF00 -c 0:boot $DISK
  sgdisk -n 0:0:+6GiB -t 0:8200 -c 0:swap $DISK
  sgdisk -n 0:0:0 -t 0:BF01 -c 0:ZFS $DISK
  ```
8. Define partition variables with:
  ```
  BOOT=$DISK-part1
  SWAP=$DISK-part2
  ZFS=$DISK-part3
  ```

### Configuring ZFS
1. Create the encrypted zpool, providing a passphrase when requested:
  ```
  zpool create -o ashift=12 -o altroot="/zfs" -O mountpoint=none -O encryption=aes-256-gcm -O keyformat=passphrase rpool $ZFS
  ```
2. Create the relevant data sets:
  ```
  zfs create -p -o mountpoint=legacy rpool/local/nix
  zfs create -p -o mountpoint=legacy rpool/safe/persist
  ```

### Mounting Filesystems
1. Create directories and mount filesystems:
  ```
  mount -t tmpfs none /mnt
  mkdir -p /mnt/{boot,nix,persist,etc/nixos,var/log}
  mkfs.vfat $BOOT
  mount $BOOT /mnt/boot
  mount -t zfs rpool/local/nix /mnt/nix
  mount -t zfs rpool/safe/persist /mnt/persist
  mkdir -p /mnt/persist/{etc/nixos,var/log}
  ```
2. Configure swap:
  ```
  mkswap -L swap $SWAP
  swapon $SWAP
  ```

## Configuring NixOS

With the disk ready, we can prepare the system configuration.

### Building the System Configuration
1. At this point, we are free to execute `nixos-generate-config --root /mnt` and
adjust the generated configurations (`/etc/nixos/hardware-configuration.nix` and
`/etc/nixos/configuration.nix`) as necessary. Alternatively we can build the
system configuration from this repository:
  ```
  nix --extra-experimental-features="nix-command flakes" develop
  nixos-rebuild --flake .
  ```

2. Similarly we can build the user configuration:
  ```
  nix --extra-experimental-features="nix-command flakes" develop
  home-manager --flake .#
  ```

## Installing NixOS

Perform the actual install with `nixos-install --no-root-passwd`. Note setting
the root password is skipped since it won't be available with reboot anyway.

# Installation

## ThinkPad X1 Carbon Gen 9 (`x1c-g9`)

This flake output targets the laptop replacing the current Arch install.
It assumes the encrypted LUKS, LVM, BTRFS, and swap layout has already been
created, with opt-in persistence for both system state and Drew's home.

### Storage preparation

Follow [docs/x1c-g9-storage-migration.md](docs/x1c-g9-storage-migration.md)
before installing. The NixOS configuration expects `/dev/vg/nixos` to contain
the BTRFS subvolumes and `/dev/vg/nixos-swap` to be available as low-priority
disk swap. ZRAM is enabled by the NixOS configuration and is preferred for
normal memory pressure.

Create the root, Nix store, persistence, and blank root subvolumes from the
BTRFS top level before mounting the install target. The `root-blank` snapshot
must be a sibling of `root`, not nested inside it, because the initrd rollback
service mounts the BTRFS top level and restores `root` from `root-blank` on
each boot.

```sh
cryptsetup open /dev/disk/by-uuid/208b84fc-d18e-42a6-9ede-489f50421821 crypted
vgchange -ay vg

mount -o subvol=/ /dev/vg/nixos /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/persist
mkdir -p /mnt/root/{boot,nix,persist}
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
umount /mnt
```

If boot fails with `Missing BTRFS blank snapshot: root-blank`, check whether
the snapshot was accidentally created inside `root`:

```sh
cryptsetup open /dev/disk/by-uuid/208b84fc-d18e-42a6-9ede-489f50421821 crypted
vgchange -ay vg

mount -o subvol=/ /dev/vg/nixos /mnt
btrfs subvolume show /mnt/root/root-blank
btrfs subvolume snapshot -r /mnt/root/root-blank /mnt/root-blank
umount /mnt
```

### Mounts

```sh
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
expected boot entries, ZRAM is active, and the NixOS disk swap LV is available:

```sh
sudo efibootmgr -v
bootctl status
free -h
zramctl
swapon --show
```

### YubiKey And SOPS Bootstrap

After the first successful boot, finish the declarative auth setup. SOPS uses a
native age key for unattended activation and a YubiKey OpenPGP encryption subkey
for human editing, recovery, and initial bootstrap. The persisted OpenSSH host
key is only SSH server identity and is unrelated to SOPS decryption.

1. Enroll the existing LUKS volume for FIDO2 if it is not already enrolled:

```sh
sudo systemd-cryptenroll --fido2-device=auto /dev/disk/by-uuid/208b84fc-d18e-42a6-9ede-489f50421821
```

2. Create the persisted native age key used by `sops-nix` if it does not
   already exist:

```sh
sudo install -d -m 700 /persist/etc/sops /persist/etc/sops/age
sudo test -f /persist/etc/sops/age/keys.txt || sudo age-keygen -o /persist/etc/sops/age/keys.txt
sudo chmod 600 /persist/etc/sops/age/keys.txt
```

Show the machine's `sops` recipient:

```sh
sudo age-keygen -y /persist/etc/sops/age/keys.txt
```

3. Inspect the YubiKey OpenPGP app before changing it. Do not reset it unless
   it is empty or you intentionally want to wipe existing OpenPGP data:

```sh
ykman openpgp info
gpg --card-status
```

If an encryption-capable OpenPGP key already exists, record its encryption
subkey fingerprint:

```sh
gpg --list-keys --with-subkey-fingerprint --keyid-format long
```

If OpenPGP is not configured, initialize it interactively:

```sh
gpg --card-edit
```

In `gpg --card-edit`, run:

```text
admin
passwd
name
lang
sex
login
generate
quit
```

Prefer `cv25519` for encryption and `ed25519` for primary/signing keys where
supported. After keys exist, set touch policy:

```sh
ykman openpgp keys set-touch enc on
ykman openpgp keys set-touch sig on
ykman openpgp keys set-touch aut on
```

Export the public key for backup/import on other machines:

```sh
gpg --armor --export YOUR_KEY_FINGERPRINT > yubikey-openpgp-public.asc
```

Add the encryption subkey fingerprint to `.sops.yaml` as the `pgp` recipient
for `secrets/x1c-g9.yaml`:

```yaml
creation_rules:
  - path_regex: secrets/x1c-g9\.yaml$
    age: age1ucfachl45fkl66fpmp5q6a406j9kwe6fc5fcuq46tphzllpt043q53pzav
    pgp: "YOUR_YUBIKEY_OPENPGP_ENCRYPTION_SUBKEY_FINGERPRINT"
```

4. Generate the values for the declarative auth secrets:

```sh
mkpasswd -m yescrypt
pamu2fcfg -u drew
```

5. Create `secrets/x1c-g9.yaml` as described in [secrets/README.md](secrets/README.md), encrypt it with `sops`, and rebuild:

```sh
sops --encrypt --in-place secrets/x1c-g9.yaml
just switch
```

When `.sops.yaml` recipients change, update the encrypted file:

```sh
sops updatekeys secrets/x1c-g9.yaml
just switch
```

Until `secrets/x1c-g9.yaml` exists, the system keeps using the bootstrap
password hash at `/persist/secrets/users/drew/password`, and PAM U2F login is
left disabled to avoid a broken login path.

### Rebuilding

```sh
just switch
```

The direct fallback command is:

```sh
sudo nixos-rebuild switch --flake .#x1c-g9
```

# NixOS Configuration

This repository contains the [NixOS](https://nixos.wiki/wiki/NixOS) and
[Home Manager](https://nixos.wiki/wiki/Home_Manager) configuration for my
ThinkPad X1 Carbon Gen 9. Requires [Nix Flakes](https://nixos.wiki/wiki/Flakes).

## Hosts

- `x1c-g9`: laptop replacement for the current Arch install.
  - Hostname: `x1c-g9`
  - Encrypted BTRFS root
  - Blank `root-blank` snapshot restored to `/` on every boot
  - Opt-in system persistence under `/persist`
  - Opt-in Home Manager persistence under `/persist/home/drew`

Install or rebuild with:

```sh
sudo nixos-rebuild switch --flake .#x1c-g9
```

See [INSTALL.md](./INSTALL.md) for the BTRFS subvolume layout and fresh install
commands.

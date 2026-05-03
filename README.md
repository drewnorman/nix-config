# NixOS Configurations

This repository contains the [NixOS](https://nixos.wiki/wiki/NixOS) and
[Home Manager](https://nixos.wiki/wiki/Home_Manager) configurations for all of
my systems. Requires [Nix Flakes](https://nixos.wiki/wiki/Flakes).

## Hosts

- `nix`: Proxmox VM intended for the homelab host `lab-nix`.
  - Hostname: `lab-nix`
  - LAN name: `nix.lab.adre.me`
  - Static IP: `172.16.0.240/24`
  - Gateway: `172.16.0.1`
  - SSH target: `ssh drew@nix.lab.adre.me`

Build or switch the Proxmox Nix host with:

```sh
sudo nixos-rebuild switch --flake .#nix
```

This host is SSH-only for now. It does not declare any HTTP service for the
homelab reverse proxy.

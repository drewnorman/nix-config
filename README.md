# NixOS Configurations

This repository contains the [NixOS](https://nixos.wiki/wiki/NixOS) and
[Home Manager](https://nixos.wiki/wiki/Home_Manager) configurations for all of
my systems. Requires [Nix Flakes](https://nixos.wiki/wiki/Flakes).

## Hosts

- `nix`: Proxmox LXC intended for the homelab host `lab-nix`.
  - Hostname: `lab-nix`
  - LAN name: `nix.lab.adre.me`
  - Static IP: `192.168.1.240/24`
  - Gateway: `192.168.1.1`
  - SSH target: `ssh drew@nix.lab.adre.me`

Build the Proxmox LXC template with:

```sh
nix build .#lab-nix-lxc-template
```

Upload the resulting tarball to Proxmox as `local:vztmpl/nixos-lxc-lab-nix.tar.xz`,
then let the homelab OpenTofu configuration create and start the container.

This host is SSH-only. It does not declare any HTTP service for the homelab
reverse proxy.

# Installation

## Proxmox Lab Nix Host (`lab-nix`)

The `lab-nix` flake output targets the homelab Proxmox LXC of the same name.
The homelab OpenTofu configuration reserves `172.16.0.240`, keeps the container
running, and AdGuard resolves `nix.lab.adre.me` to that address.

### 1. Build the LXC template

```sh
nix build .#lab-nix-lxc-template
```

### 2. Upload to Proxmox

Upload `result` to the Proxmox host as:

```
local:vztmpl/nixos-lxc-lab-nix.tar.xz
```

### 3. Provision with OpenTofu

Apply the homelab OpenTofu configuration. It will create and start the
container from the uploaded template.

### 4. Connect

```sh
ssh drew@nix.lab.adre.me
```

### Rebuilding

Once the container is running, rebuild in place from this repo:

```sh
nixos-rebuild switch --flake .#lab-nix --target-host drew@nix.lab.adre.me --use-remote-sudo
```

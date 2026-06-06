set dotenv-load := false

switch:
    nh os switch

build:
    nh os build

boot:
    nh os boot

check:
    nix flake check

test-build:
    nix build .#nixosConfigurations.x1c-g9.config.system.build.toplevel --no-link

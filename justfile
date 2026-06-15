set dotenv-load := false

install-hooks:
    git config core.hooksPath .githooks

switch:
    nh os switch

build:
    nh os build

boot:
    nh os boot

check:
    nix flake check

fmt:
    nix fmt

check-fmt:
    nix fmt -- --check

test-build:
    nix build .#nixosConfigurations.x1c-g9.config.system.build.toplevel --no-link

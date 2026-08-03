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

update-codex-desktop:
    #!/usr/bin/env bash
    set -euo pipefail

    lock_backup="$(mktemp)"
    cp flake.lock "$lock_backup"

    restore_lock() {
        trap - ERR INT TERM
        cp "$lock_backup" flake.lock
        rm -f "$lock_backup"
    }
    trap 'status=$?; restore_lock; exit "$status"' ERR
    trap 'restore_lock; exit 130' INT
    trap 'restore_lock; exit 143' TERM

    nix flake update codex-desktop-linux
    just test-build

    trap - ERR INT TERM
    rm -f "$lock_backup"

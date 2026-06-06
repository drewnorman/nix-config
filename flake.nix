{
  description = "Drew Norman's NixOS and Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "git+https://github.com/Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-wrapper-modules = {
      url = "git+https://github.com/BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, impermanence, sops-nix, ... }:
    let
      system = "x86_64-linux";
      homeManagerConfig = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit inputs;
        };
        home-manager.users.drew = import ./home/drew/home.nix;
      };
    in
    {
      nixosConfigurations = {
        x1c-g9 = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/x1c-g9/configuration.nix
            ./modules/nixos/btrfs-impermanence.nix
            ./modules/nixos/yubikey-sops.nix
            impermanence.nixosModules.impermanence
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            homeManagerConfig
          ];
        };
      };

      devShells.${system}.default = import ./shell.nix {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      };
    };
}

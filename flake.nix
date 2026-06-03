{
  description = "Drew Norman's NixOS and Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = inputs@{ nixpkgs, home-manager, impermanence, ... }:
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
            impermanence.nixosModules.impermanence
            home-manager.nixosModules.home-manager
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

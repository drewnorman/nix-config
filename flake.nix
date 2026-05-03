{
  description = "Drew Norman's NixOS and Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      nixHostModules = [
        ./hosts/nix/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.drew = import ./home/drew/home.nix;
        }
      ];
    in
    {
      nixosConfigurations = {
        nix = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = nixHostModules;
        };

        lab-nix = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = nixHostModules;
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

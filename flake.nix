{
  description = "My home manager and system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
    	url = "github:nix-community/home-manager";
	inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = inputs:
    let 
      inherit (inputs.nixpkgs.lib) genAttrs systems;
      forAllSystems = genAttrs systems.flakeExposed;
    in rec
  {
    packages = forAllSystems (system:
      import inputs.nixpkgs {
	inherit system;
	config.allowUnfree = true;
      }
    );

    devShells = forAllSystems (system: {
      default = import ./shell.nix {
	pkgs = packages.${system};
      };
    });

    nixosConfigurations = {
      xps15-9550 = inputs.nixpkgs.lib.nixosSystem rec {
	system = "x86_64-linux";
	pkgs = packages.${system};
	modules = [ ./configuration.nix ];
	specialArgs = { inherit inputs; };
      };
    };

    homeConfigurations = {
      "drew@xps15-9550" = inputs.home-manager.lib.homeManagerConfiguration {
	pkgs = packages."x86_64-linux";
	modules = [ ./home.nix ];
	extraSpecialArgs = { inherit inputs; };
      };
    };
  };
}

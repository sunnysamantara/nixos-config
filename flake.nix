{
  description = "survival suite";

  inputs = {
    # NixOS official package source, here using the nixos-25.11 branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lobo-grub-theme = {
      url = "github:rats-scamper/LoboGrubTheme";
      flake = false; # plain source repo, no flake.nix
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    username = "sunny";
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations = {
      acer-aspire = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.solaar.nixosModules.default
          ./system/configuration.nix
        ];
      };
    };
    homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {inherit system;};
      modules = [
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.nvf.homeManagerModules.default
        ./user/home.nix
        {
          home = {
            inherit username;
            homeDirectory = "/home/${username}";
          };
          home-manager = {
            backupFileExtension = "backup";
            overwriteBackup = true;
          };
        }
      ];
    };
  };
}

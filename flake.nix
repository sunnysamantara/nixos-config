{
  description = "survival suite";

  inputs = {
    # NixOS official package source, here using the nixos-25.11 branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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
    openlogi = {
      url = "github:AprilNEA/OpenLogi";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    lobo-grub-theme = {
      url = "github:rats-scamper/LoboGrubTheme";
      flake = false; # plain source repo, no flake.nix
    };
    dedsec-grub-theme = {
      url = "gitlab:VandalByte/dedsec-grub-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qylock.url = "github:Darkkal44/qylock";
    # zen-browser = {
    #   url = "github:youwen5/zen-browser-flake";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kwin-effects-better-blur-dx = {
      url = "github:xarblu/kwin-effects-better-blur-dx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    obsidian-extensions = {
      url = "github:karaolidis/nix-obsidian-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # devenv = {
    #   url = "github:cachix/devenv";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      username = "sunny";
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
        acer-aspire = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            inputs.dedsec-grub-theme.nixosModule
            inputs.qylock.nixosModules.default
            inputs.catppuccin.nixosModules.catppuccin
            inputs.solaar.nixosModules.default
            inputs.openlogi.nixosModules.default
            ./system/configuration.nix
          ];
        };
      };
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true; # needed for obsidian itself
          overlays = [ inputs.obsidian-extensions.overlays.default ];
        };
        extraSpecialArgs = { inherit inputs; };
        modules = [
          inputs.catppuccin.homeModules.catppuccin
          inputs.plasma-manager.homeModules.plasma-manager
          inputs.nvf.homeManagerModules.default
          ./user/home.nix
          {
            home = {
              inherit username;
              homeDirectory = "/home/${username}";
            };
          }
        ];
      };
      # devShells.${system} = {
      #   default = inputs.devenv.lib.mkShell {
      #     inherit pkgs inputs;
      #     modules = [
      #       # Base configuration stub to resolve missing internal attribute bugs
      #       ({config, ...}: {
      #         cachix.enable = false;
      #       })
      #     ];
      #   };
      # };
    };
}

{
  description = "survival suite";

  inputs = {
    # NixOS official package source, here using the nixos-25.11 branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
  };

    outputs = inputs@{ nixpkgs, home-manager, nvf, ... }: {
    nixosConfigurations = {
      acer-aspire = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
            };
        modules = [
          nvf.nixosModules.default
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.sunny = ./home.nix;
            home-manager.extraSpecialArgs = { inherit inputs;};
            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }

        ];
      };
    };
  };
}

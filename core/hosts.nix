{
  inputs,
  config,
  lib,
  ...
}:
let
  # Shape of each entry under `hosts.<name>`.
  hostType = { name, ... }: {
    options = {
      hostname = lib.mkOption {
        type = lib.types.str;
        default = name; # defaults to the attribute name
        description = "networking.hostName for this host.";
      };
      system = lib.mkOption {
        type = lib.types.str;
        default = "x86_64-linux";
        description = "Host platform.";
      };
      users = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Users on this host. Each name needs flake.modules.nixos.<user>
          and flake.modules.homeManager.<user> (see users/<user>.nix).
        '';
      };
      features = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Names of flake.modules.nixos.<feature> to include.";
      };
      extra = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        description = "Extra NixOS modules (hardware file, stateVersion, ...).";
      };
    };
  };

  # NixOS features included on every host, in addition to each host's own list.
  baseFeatures = [ "boot" ];

  # Look up a registered module, failing with a readable message.
  getMod =
    class: name:
    config.flake.modules.${class}.${name}
      or (throw "No flake.modules.${class}.${name} defined (referenced from a host in `hosts`).");

  mkHost =
    host:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        {
          nixpkgs.hostPlatform = host.system;
          networking.hostName = host.hostname;
          nixpkgs.config.allowUnfree = true; # all hosts (home-manager inherits via useGlobalPkgs)
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users = lib.genAttrs host.users (getMod "homeManager");
          };
        }
      ]
      ++ map (getMod "nixos") baseFeatures
      ++ map (getMod "nixos") host.users
      ++ map (getMod "nixos") host.features
      ++ host.extra;
    };
in
{
  options.hosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule hostType);
    default = { };
    description = "Host registry. Each entry becomes flake.nixosConfigurations.<name>.";
  };

  config.flake.nixosConfigurations = lib.mapAttrs (_: mkHost) config.hosts;
}

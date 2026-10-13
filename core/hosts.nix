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
      services = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Names of flake.services.<service> to include.";
      };
      extra = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        description = "Extra NixOS modules (hardware file, stateVersion, ...).";
      };
    };
  };

  # NixOS features included on every host, in addition to each host's own list.
  baseFeatures = [ "core" "internationalization" ];

  # System services included on every host, in addition to each host's own list.
  baseServices = [ "boot" ];

  # Look up a registered module, failing with a readable message.
  getMod =
    class: name:
    config.flake.modules.${class}.${name}
      or (throw "No flake.modules.${class}.${name} defined (referenced from a host in `hosts`).");

  # Look up a registered service. Separate namespace from features, so a
  # feature name listed under `services` (or vice-versa) fails evaluation.
  getService =
    name:
    config.flake.services.${name}
      or (throw "No flake.services.${name} defined (referenced from a host in `hosts`).");

  mkHost =
    host:
    let
      # Stable nixpkgs (nixos-26.05) for `stable-pkgs.X` in any NixOS or
      # home-manager module; `pkgs.X` remains nixos-unstable.
      customOverlay = import ../overlays/default.nix;
      stable-pkgs = import inputs.nixpkgs-stable {
        inherit (host) system;
        config.allowUnfree = true;
        overlays = [ customOverlay ];
      };
      pkgs-unstable = import inputs.nixpkgs {
        inherit (host) system;
        config.allowUnfree = true;
        overlays = [ customOverlay ];
      };
    in
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs stable-pkgs;
      };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        {
          nixpkgs.hostPlatform = host.system;
          networking.hostName = host.hostname;
          nixpkgs.overlays = [ customOverlay ];
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs stable-pkgs;
              pkgs = pkgs-unstable;
            };
            users = lib.genAttrs host.users (getMod "homeManager");
          };
        }
      ]
      ++ map (getMod "nixos") baseFeatures
      ++ map getService baseServices
      ++ map (getMod "nixos") host.users
      ++ map (getMod "nixos") host.features
      ++ map getService host.services
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

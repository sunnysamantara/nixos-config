{ inputs, ... }:
{
  # Provides the `flake.modules.<class>.<name>` option, where every
  # feature/user file registers its NixOS and home-manager modules.
  imports = [ inputs.flake-parts.flakeModules.modules ];

  # Systems for perSystem outputs (formatter, devShells, ...).
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
}

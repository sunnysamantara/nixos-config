final: prev:
let
  # Auto-discover all package directories under pkgs/
  pkgsDir = ../pkgs;
  packageDirs = builtins.readDir pkgsDir;
  
  # For each directory, create a package attr by callPackage-ing its default.nix
  mkPackage = name: _: prev.callPackage (pkgsDir + "/${name}") { };
in
  builtins.mapAttrs mkPackage packageDirs

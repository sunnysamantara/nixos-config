{ pkgs, ... }:
{

  home.packages = [
    pkgs.lshw # unstable (nixos-unstable)
  ];
}
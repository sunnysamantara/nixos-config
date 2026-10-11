{ pkgs, ... }:
{

  environment.systemPackages = [
    pkgs.lshw # unstable (nixos-unstable)
  ];
}
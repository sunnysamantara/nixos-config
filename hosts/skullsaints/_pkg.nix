{ pkgs, stable-pkgs, ... }:
{

  environment.systemPackages = [
    stable-pkgs.lshw # stable (nixos-26.05)
  ];
}
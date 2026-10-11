{ pkgs, stable-pkgs, ... }:
{

  home.packages = [
    stable-pkgs.wget # stable (nixos-26.05)
  ];
}
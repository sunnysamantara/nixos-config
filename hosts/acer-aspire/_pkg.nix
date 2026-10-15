{ pkgs, ... }:
{

  environment.systemPackages = [
    pkgs.bitwarden-desktop # unstable (nixos-unstable)
    pkgs.superfile
    pkgs.brave
  ];

  programs.bat.enable = true;

  networking.networkmanager.enable = true;
}

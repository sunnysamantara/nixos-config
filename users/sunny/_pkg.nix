{ pkgs, ... }:
{

  home.packages = [
    pkgs.testdisk # unstable (nixos-unstable)
    pkgs.firefox
    pkgs.obs-studio
    pkgs.veracrypt
    pkgs.bitwarden-desktop
    pkgs.photocraft
    pkgs.scrcpy
    pkgs.libreoffice-qt
    pkgs.gimp-with-plugins
  ];
}

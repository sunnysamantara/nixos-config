{ pkgs, ... }:
{

  environment.systemPackages = [
    pkgs.bitwarden-desktop # unstable (nixos-unstable)
    pkgs.superfile
    pkgs.brave
    pkgs.wget
    pkgs.lshw
    pkgs.libheif
    pkgs.resvg
    pkgs.btop
    pkgs.gdu
  ];

  programs.bat.enable = true;

  security.polkit.enable = true;

  services.printing.enable = true;

  services = {
    fstrim.enable = true;
  };
}

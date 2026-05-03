{
  config,
  pkgs,
  inputs,
  ...
}: let
  lobocorp-theme = pkgs.stdenvNoCC.mkDerivation {
    name = "lobo-grub-theme";
    src = inputs.lobo-grub-theme;

    installPhase = ''
      mkdir -p $out
      cp -r lobocorp/* $out/
    '';
  };
in {
  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot"; # ← use the same mount point here.
    };
    grub = {
      enable = true;
      efiSupport = true;
      useOSProber = true;
      #efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
      device = "nodev";
      configurationLimit = 10;
      default = "saved";
      theme = lobocorp-theme;
    };
    timeout = 5;
    # Disable systemd-boot
    systemd-boot.enable = false;
  };
}

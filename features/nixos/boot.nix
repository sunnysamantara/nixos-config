{ ... }:
{
  flake.modules.nixos.boot = { pkgs, ... }: {
    boot.loader = {
      efi = {
        #canTouchEfiVariables = true;
        efiSysMountPoint = "/boot"; # ← use the same mount point here.
      };
      grub = {
        enable = true;
        efiSupport = true;
        useOSProber = true;
        efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
        device = "nodev";
        configurationLimit = 10;
        default = "saved";
      };
      timeout = 5;
      # Disable systemd-boot
      systemd-boot.enable = false;
    };
  };
}

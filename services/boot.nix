{ ... }:
{
  flake.services.boot = { pkgs, ... }: {
    boot.loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot"; # ← use the same mount point here.
      };
      grub = {
        enable = true;
        efiSupport = true;
        useOSProber = true;
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

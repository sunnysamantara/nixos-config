{ pkgs, lib, ... }:
{
  flake.services.yubikey = { pkgs, config, lib, ... }: {
    # Enable PCSCd and YubiKey udev rules
    services.pcscd.enable = true;
    programs.yubikey-manager.enable = true;

    # Packages for YubiKey/U2F operations
    environment.systemPackages = with pkgs; [
      pam_u2f
      pamtester
    ];

    # Base U2F configuration
    security.pam.u2f = {
      enable = true;
      control = "sufficient";
      settings = {
        authfile = "/run/secrets/u2f_keys";
        cue = true;
        interactive = false;
      };
    };

    # PAM services
    security.pam.services = {
      login = {
        unixAuth = true;
        u2fAuth = lib.mkForce false;
        kwallet.enable = true;
      };
      kde = {
        unixAuth = true;
        u2fAuth = true;
        kwallet.enable = true;
      };
      sudo = {
        unixAuth = true;
        u2fAuth = true;
      };
    };
  };
}

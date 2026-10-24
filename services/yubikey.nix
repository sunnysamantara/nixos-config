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

    # Enable U2F for specific PAM services
    security.pam.services = {
      # Login/SDDM - password only for now to fix login
      login = {
        unixAuth = true;
        kwallet.enable = true;
      };
      # Lockscreen (kscreenlocker) - either-or
      kde = {
        unixAuth = true;
        u2fAuth = true;
        kwallet.enable = true;
      };
      # Sudo - either-or
      sudo = {
        unixAuth = true;
        u2fAuth = true;
      };
    };

    # SDDM/login: password only, ensure kwallet can get PAM_AUTHTOK
    security.pam.services.login.rules.auth = { };

    # Sudo: either password OR YubiKey
    security.pam.services.sudo.rules.auth = {
      u2f = {
        order = 50;
        control = lib.mkForce "sufficient";
        modulePath = lib.mkForce "${pkgs.pam_u2f}/lib/security/pam_u2f.so";
        settings = lib.mkForce {
          authfile = "/run/secrets/u2f_keys";
          cue = true;
          interactive = false;
        };
      };
      unix = {
        order = 100;
        control = lib.mkForce "sufficient";
        modulePath = lib.mkForce "${pkgs.pam}/lib/security/pam_unix.so";
        settings = lib.mkForce {
          nullok = false;
          try_first_pass = true;
        };
      };
    };

    # KDE/lockscreen: either password OR YubiKey
    security.pam.services.kde.rules.auth = {
      u2f = {
        order = 50;
        control = lib.mkForce "sufficient";
        modulePath = lib.mkForce "${pkgs.pam_u2f}/lib/security/pam_u2f.so";
        settings = lib.mkForce {
          authfile = "/run/secrets/u2f_keys";
          cue = true;
          interactive = false;
        };
      };
      unix = {
        order = 100;
        control = lib.mkForce "sufficient";
        modulePath = lib.mkForce "${pkgs.pam}/lib/security/pam_unix.so";
        settings = lib.mkForce {
          nullok = false;
          try_first_pass = true;
        };
      };
    };
  };
}

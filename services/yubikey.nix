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
      control = "sufficient"; # overridden per-service as needed
      settings = {
        authfile = "/run/secrets/u2f_keys";
        cue = true;
        interactive = false;
      };
    };

    # Enable U2F for specific PAM services
    # SDDM uses 'login' substack, KScreenLocker uses 'kde'
    security.pam.services = {
      # Login/SDDM - require both factors, kwallet must get password
      login = {
        u2fAuth = true;
        unixAuth = true;
        kwallet.enable = true;
      };
      # Lockscreen (kscreenlocker) - either-or
      kde = {
        u2fAuth = true;
        unixAuth = true;
        kwallet.enable = true;
      };
      # Sudo - either-or
      sudo = {
        u2fAuth = true;
        unixAuth = true;
      };
    };

    # Enforce ordering/controls per service
    # Login/SDDM: collect password first so pam_unix sets PAM_AUTHTOK for kwallet,
    # require both password and YubiKey
    security.pam.services.login.rules.auth = {
      unix = {
        control = lib.mkForce "required";
        modulePath = "${pkgs.pam}/lib/security/pam_unix.so";
        settings = {
          nullok = lib.mkForce false;
          try_first_pass = lib.mkForce false;
        };
      };
      u2f = {
        order = config.security.pam.services.login.rules.auth.unix.order + 10;
        control = lib.mkForce "required";
        modulePath = "${pkgs.pam_u2f}/lib/security/pam_u2f.so";
        settings = {
          authfile = "/run/secrets/u2f_keys";
          cue = true;
          interactive = false;
        };
      };
    };

    # Sudo: either password OR YubiKey
    security.pam.services.sudo.rules.auth = {
      u2f = {
        order = config.security.pam.services.sudo.rules.auth.unix.order - 10;
        control = lib.mkForce "sufficient";
        modulePath = "${pkgs.pam_u2f}/lib/security/pam_u2f.so";
        settings = {
          authfile = "/run/secrets/u2f_keys";
          cue = true;
          interactive = false;
        };
      };
      unix = {
        control = lib.mkForce "sufficient";
        modulePath = "${pkgs.pam}/lib/security/pam_unix.so";
        settings = {
          nullok = lib.mkForce false;
          try_first_pass = lib.mkForce true;
        };
      };
    };

    # KDE/lockscreen: either password OR YubiKey
    security.pam.services.kde.rules.auth = {
      u2f = {
        order = config.security.pam.services.kde.rules.auth.unix.order - 10;
        control = lib.mkForce "sufficient";
        modulePath = "${pkgs.pam_u2f}/lib/security/pam_u2f.so";
        settings = {
          authfile = "/run/secrets/u2f_keys";
          cue = true;
          interactive = false;
        };
      };
      unix = {
        control = lib.mkForce "sufficient";
        modulePath = "${pkgs.pam}/lib/security/pam_unix.so";
        settings = {
          nullok = lib.mkForce false;
          try_first_pass = lib.mkForce true;
        };
      };
    };
  };
}

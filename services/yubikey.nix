{ ... }:
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

    # Configure PAM U2F
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
    # SDDM uses 'login' substack, KScreenLocker uses 'kde'
    security.pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
      kde.u2fAuth = true;
    };

    # Keep KWallet enabled for unlock - will only auto-unlock if pam_unix provides PAM_AUTHTOK
    # (i.e., if U2F fails/times out and falls back to password)
    security.pam.services.login.kwallet.enable = true;
    security.pam.services.kde.kwallet.enable = true;
  };
}

{
  lib,
  pkgs,
  configVars,
  ...
}: {
  environment.systemPackages = with pkgs; [
    yubioath-flutter
    yubikey-manager
    pam_u2f
    yubikey-touch-detector
  ];
  services = {
    pcscd.enable = true;
    udev.packages = [pkgs.yubikey-personalization];
    yubikey-agent.enable = true;
  };
  security.pam = {
    sshAgentAuth.enable = true;
    u2f = {
      enable = true;
      settings = {
        interactive = true;
        cue = true;
        authFile = "/home/sunny/.config/Yubico/u2f_keys";
        # debug = true;
      };
    };
    services = {
      login.u2fAuth = true;
      sudo = {
        u2fAuth = true;
        sshAgentAuth = true;
      };
    };
  };
}

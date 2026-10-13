{ ... }:
{
  flake.modules.nixos.openlogi = { pkgs, ... }: {
    # Local-first Logitech HID++ manager. Uses the nixpkgs package (served from
    # cache.nixos.org — no Rust build). Installs the package (CLI + GUI +
    # 70-openlogi.rules udev access to hidraw/uinput/event nodes) and defines
    # systemd.user.services.openlogi-agent.
    # NOTE: conflicts with Solaar over HID++ receiver access — don't run both.
    environment.systemPackages = [ pkgs.openlogi ];
    services.udev.packages = [ pkgs.openlogi ];

    systemd.user.services.openlogi-agent = {
      description = "OpenLogi background agent";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.openlogi}/bin/openlogi-agent";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}

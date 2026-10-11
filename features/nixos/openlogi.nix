{ inputs, ... }:
{
  flake.modules.nixos.openlogi = { ... }: {
    # Native local-first Logitech HID++ manager (Rust). The upstream module
    # installs the package + 70-openlogi.rules (udev access to hidraw/uinput/
    # event nodes) and defines systemd.user.services.openlogi-agent.
    # NOTE: conflicts with Solaar over HID++ receiver access — don't run both.
    imports = [ inputs.openlogi.nixosModules.default ];

    programs.openlogi = {
      enable = true;
      launchAtLogin = true;
    };
  };
}

{ ... }:
{
  flake.modules.nixos.solaar = { ... }: {
    # Native NixOS module (the Svenum/Solaar-Flake input is discontinued on
    # 26.11). `enable` only installs Solaar + the udev rules; the legacy
    # `services.solaar.enable` always ran the tray service, so opt in explicitly.
    programs.solaar = {
      enable = true;
      userService.enable = true;
      userService.window = "hide";
    };
  };
}

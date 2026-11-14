{ ... }:
{
  flake.modules.nixos.kde = { pkgs, ... }: {
    # Minimal NixOS side: install + register the Plasma session. All plasma
    # *configuration* and apps live in the home-manager kde/ features.
    services.desktopManager.plasma6.enable = true;
    environment.plasma6.excludePackages = [ pkgs.kdePackages.discover ];
    environment.systemPackages = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    programs.fuse.userAllowOther = true;

    # The nixpkgs Electron wrapper only appends --ozone-platform-hint=auto and
    # the Wayland flags when this is set; otherwise Electron falls back to
    # XWayland. Needed for pkgs.opencode-desktop (features/homeManager/opencode.nix).
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
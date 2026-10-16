{ ... }:
{
  flake.modules.nixos.kde = { pkgs, ... }: {
    # Minimal NixOS side: install + register the Plasma session. All plasma
    # *configuration* and apps live in the home-manager kde/ features.
    services.desktopManager.plasma6.enable = true;
    environment.plasma6.excludePackages = [ pkgs.kdePackages.discover ];
    environment.systemPackages = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    programs.fuse.userAllowOther = true;
  };
}
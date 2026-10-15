{ config, ... }:
{
  flake.modules.homeManager.kde-all = { ... }: {
    # Enable the whole KDE feature family in one go. Individual kde-* features
    # remain opt-in if you only want a subset.
    imports = with config.flake.modules.homeManager; [
      kde
      kde-desktop
      kde-workspace
      kde-kwin
      kde-power
      kde-session
      kde-krunner
      kde-fonts
      kde-apps
      kde-konsole
      nixdatifier
    ];
  };
}
{ ... }:
{
  flake.modules.homeManager.kde-session = { pkgs, ... }: {
    programs.plasma.session = {
      general.askForConfirmationOnLogout = true;
      sessionRestore.restoreOpenApplicationsOnLogin = "onLastLogout";
    };

    programs.plasma.kscreenlocker = {
      # appearance.wallpaperPictureOfTheDay = {
      #   provider = "natgeo";
      #   updateOverMeteredConnection = false;
      # };
      appearance.wallpaperSlideShow = {
        path = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/";
      };
      autoLock = true;
      timeout = 10;
    };

    programs.plasma.desktop.mouseActions.verticalScroll = "switchVirtualDesktop";
  };
}
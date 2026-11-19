{ ... }:
{
  flake.modules.homeManager.kde-desktop =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      # Konveyor replaces the launcher/taskbar and parks its monitor overlays in
      # the system tray. Keep the stock Plasma widgets on hosts without the KWin
      # effect (e.g. the router).
      konveyor = osConfig.programs.konveyor.enableWidgets or false;
      overlayHosts = [
        "org.devl0rd.sysmon.overlay"
        "org.devl0rd.procmon.overlay"
        "org.devl0rd.routermon.overlay"
      ];
    in
    {
      home.packages = [ pkgs.appmenu-glib-translator ];

      home.sessionVariables = {
        GTK_MODULES = "appmenu-gtk-module";
      };

      programs.plasma.panels = [
        {
          location = "bottom";
          alignment = "center";
          floating = true;
          lengthMode = "fit";
          height = 44;
          opacity = "translucent";
          hiding = "dodgewindows";
          screen = "all";
          widgets =
            if konveyor then
              [
                "org.devl0rd.portal.launcher"
                "org.devl0rd.taskbar"
              ]
            else
              [
                "org.kde.plasma.kickoff"
                "org.kde.plasma.icontasks"
                # "org.kde.plasma.marginsseparator"
                "org.kde.plasma.trash"
                "org.kde.plasma.showdesktop"
              ];
        }
        {
          location = "top";
          lengthMode = "fill";
          height = 30;
          screen = "all";
          alignment = "left";
          opacity = "opaque";
          floating = false;
          widgets =
            if konveyor then
              [
                "org.kde.plasma.appmenu"
                "org.kde.plasma.panelspacer"
                {
                  name = "org.kde.plasma.digitalclock";
                  config.Appearance.showDate = false;
                }
                "org.kde.plasma.panelspacer"
                "org.devl0rd.sysmon"
                "org.devl0rd.procmon"
                "org.devl0rd.logmon.journal"
                "org.kde.plasma.systemtray"
              ]
            else
              [
                "org.kde.plasma.appmenu"
                "org.kde.plasma.panelspacer"
                {
                  name = "org.kde.plasma.digitalclock";
                  config.Appearance.showDate = false;
                }
                "org.kde.plasma.panelspacer"
                "org.kde.plasma.systemtray"
                # {
                #   systemTray.items = {
                #     # Solaar's StatusNotifier id; keep it in the popup, not the bar.
                #     # Nixdatifier likewise — its tray icon lives in the popup only.
                #     # Konveyor's three monitor overlays are added as hidden hosts so
                #     # they can be enabled from the tray without taking bar space.
                #     hidden = [ "indicator-solaar" "Nixdatifier" ] ++ lib.optionals konveyor overlayHosts;
                #     extra = lib.optionals konveyor overlayHosts;
                #     shown = [
                #       "org.kde.plasma.clipboard"
                #       "org.kde.plasma.volume"
                #       "org.kde.plasma.networkmanagement"
                #       "org.kde.plasma.battery"
                #       "org.kde.plasma.weather"
                #       "org.kde.plasma.notifications"
                #     ];
                #   };
                # }
              ];
        }
      ];
    };
}

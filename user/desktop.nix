{pkgs, ...}: {
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
      widgets = [
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
      widgets = [
        "org.kde.plasma.appmenu"
        "org.kde.plasma.panelspacer"
        {
          name = "org.kde.plasma.digitalclock";
          config.Appearance.showDate = false;
        }
        "org.kde.plasma.panelspacer"
        {
          systemTray.items = {
            shown = [
              "org.kde.plasma.clipboard"
              "org.kde.plasma.volume"
              "org.kde.plasma.networkmanagement"
              "org.kde.plasma.battery"
              "org.kde.plasma.weather"
              "org.kde.plasma.notifications"
            ];
          };
        }
      ];
    }
  ];
}

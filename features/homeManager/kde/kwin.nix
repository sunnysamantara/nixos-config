{ ... }:
{
  flake.modules.homeManager.kde-kwin = { pkgs, inputs, ... }: {
    home.packages = [
      inputs.kwin-effects-better-blur-dx.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    programs.plasma.kwin = {
      effects = {
        blur = {
          enable = true;
          noiseStrength = 0;
          strength = 8;
        };
        desktopSwitching = {
          animation = "fade";
          navigationWrapping = true;
        };
        # dimInactive.enable = true;
        dimAdminMode.enable = true;
        # hideCursor = {
        #   enable = true;
        #   hideOnInactivity = 30;
        #   hideOnTyping = true;
        # };
        shakeCursor.enable = true;
        slideBack.enable = true;
        translucency.enable = true;
        wobblyWindows.enable = true;
      };
      titlebarButtons.left = [
        "keep-above-windows"
        "keep-below-windows"
      ];
      titlebarButtons.right = [
        "help"
        "minimize"
        "maximize"
        "close"
      ];
    };

    programs.plasma.shortcuts.kwin = {
      "Keep Window Above Others" = "Meta+Ctrl+T";
      "Keep Window Below Others" = "Meta+Ctrl+B";
    };

    programs.plasma.hotkeys.commands = {
      launch-konsole = {
        name = "Launch Konsole";
        key = "Meta+K";
        command = "konsole";
      };
    };
  };
}
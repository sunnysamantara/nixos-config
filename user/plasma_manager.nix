{pkgs, ...}: {
  # programs.konsole changes has been moved to shell.nix
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = ["RobotoMono Nerd Font" "Noto Sans"];
      serif = ["RobotoMono Nerd Font" "Noto Serif"];
      monospace = ["RobotoMono Nerd Font Mono" "Noto Sans Mono"];
      emoji = ["Noto Color Emoji"];
    };
  };
  # home.sessionVariables = {
  #   QT_STYLE_OVERRIDE = "breeze";
  #   KVANTUM_THEME = "Catppuccin-Mocha-Sapphire";
  # };
  programs.plasma = {
    enable = true;
    overrideConfig = true;
    workspace = {
      # Global Theme (look-and-feel package identifier)
      # lookAndFeel = "org.kde.breezedark.desktop";
      # Plasma shell chrome (breeze-dark, etc.)
      theme = "breeze-dark";

      # Color scheme applied to all Qt/KDE windows
      colorScheme = "CatppuccinFrappeBlue";

      # Cursor — correct submodule path (cursorTheme was renamed and removed)
      cursor = {
        theme = "catppuccin-mocha-dark-cursors";
        animationTime = 5;
        cursorFeedback = "Bouncing";
        size = 23;
        taskManagerFeedback = true;
      };

      # Icon theme
      iconTheme = "Papirus-Dark";

      # Solid colour fallback wallpaper — correct option name
      wallpaperPlainColor = "30,30,46"; # #1e1e2e Mocha Base in R,G,B
    };
    workspace.windowDecorations = {
      theme = "Breeze";
      library = "org.kde.breeze";
    };
    configFile."kdeglobals"."KDE"."widgetStyle" = "breeze";

    #
    # # Tell Kvantum which theme to use
    # configFile."Kvantum/kvantum.kvconfig"."General"."theme" = "Catppuccin-Mocha-Sapphire";
    #
    # # GTK 3 integration — each key must be its own configFile entry
    # configFile."gtk-3.0/settings.ini"."Settings"."gtk-theme-name" = "Catppuccin-Mocha-Standard-Sapphire-Dark";
    # configFile."gtk-3.0/settings.ini"."Settings"."gtk-icon-theme-name" = "Papirus-Dark";
    # configFile."gtk-3.0/settings.ini"."Settings"."gtk-cursor-theme-name" = "catppuccin-mocha-dark-cursors";
    # configFile."gtk-3.0/settings.ini"."Settings"."gtk-font-name" = "RobotoMono Nerd Font 10";
    input.keyboard = {
      numlockOnStartup = "on";
    };
    hotkeys.commands = {
      launch-konsole = {
        name = "Launch Konsole";
        key = "Meta+K";
        command = "konsole";
      };
    };
    shortcuts = {
      kwin = {
        "Keep Window Above Others" = "Meta+Ctrl+T";
        "Keep Window Below Others" = "Meta+Ctrl+B";
      };
    };
    kwin = {
      effects = {
        blur = {
          enable = true;
          noiseStrength = 0;
          strength = 6;
        };
        slideBack.enable = true;
        translucency.enable = true;
        wobblyWindows.enable = true;
      };
    };
    fonts = {
      fixedWidth = {
        family = "RobotoMono Nerd Font";
        pointSize = 10;
      };
      general = {
        family = "RobotoMono Nerd Font";
        pointSize = 10;
      };
      menu = {
        family = "RobotoMono Nerd Font";
        pointSize = 10;
      };
      small = {
        family = "RobotoMono Nerd Font";
        pointSize = 8;
      };
      toolbar = {
        family = "RobotoMono Nerd Font";
        pointSize = 10;
      };
      windowTitle = {
        family = "RobotoMono Nerd Font";
        pointSize = 10;
        weight = 600;
      };
    };
  };
}

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
    krunner = {
      shortcuts.launch = "Meta";
      position = "center";
      activateWhenTypingOnDesktop = true;
      historyBehavior = "enableAutoComplete";
    };
    kscreenlocker = {
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
    workspace = {
      # Global Theme (look-and-feel package identifier)
      lookAndFeel = "Catppuccin-Mocha-Teal";
      # Plasma shell chrome (breeze-dark, etc.)
      widgetStyle = "catppuccin-mocha-teal-standard";
      # theme = "Catppuccin-Frappe-Blue";
      enableMiddleClickPaste = true;
      # Color scheme applied to all Qt/KDE windows
      colorScheme = "CatppuccinMochaTeal";

      # Cursor — correct submodule path (cursorTheme was renamed and removed)
      cursor = {
        theme = "graphite-dark";
        #this has been moved to theme.nix
        animationTime = 5;
        cursorFeedback = "Bouncing";
        size = 23;
        taskManagerFeedback = true;
      };

      # Icon theme
      iconTheme = "Papirus-Dark";
      wallpaperSlideShow = {
        path = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/";
        interval = 300;
      };
      # Solid colour fallback wallpaper — correct option name
      # wallpaperPlainColor = "30,30,46"; # #1e1e2e Mocha Base in R,G,B
    };
    # workspace.windowDecorations = {
    #   theme = "Breeze";
    #   library = "org.kde.breeze";
    # };
    # workspace.windowDecorations = {
    #   library = "Catppuccin-Frappe-Modern";
    #   theme = "Catppuccin-Frappe-Modern";
    #   /*
    #   buttonSize = "Tiny";
    #   */
    # };
    # configFile.kwinrc."org.kde.kdecoration2".BorderSize = "Tiny";
    # configFile."kdeglobals"."KDE"."widgetStyle" = "breeze";

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
    powerdevil = {
      AC = {
        autoSuspend = {
          action = "hibernate";
          idleTimeout = 1800;
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 1680;
        };
        powerButtonAction = "turnOffScreen";
        turnOffDisplay.idleTimeoutWhenLocked = 60;
        powerProfile = "balanced";
      };
      battery = {
        autoSuspend = {
          action = "hibernate";
          idleTimeout = 900;
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 780;
        };
        powerButtonAction = "shutDown";
        turnOffDisplay.idleTimeoutWhenLocked = 30;
        powerProfile = "powerSaving";
        whenLaptopLidClosed = "hibernate";
      };
      batteryLevels.lowLevel = 20;
      lowBattery = {
        autoSuspend = {
          action = "hibernate";
          idleTimeout = 300;
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 180;
        };
        powerButtonAction = "shutDown";
        powerProfile = "powerSaving";
        turnOffDisplay.idleTimeout = 180;
        whenLaptopLidClosed = "shutDown";
      };
    };
    session = {
      general.askForConfirmationOnLogout = true;
      sessionRestore.restoreOpenApplicationsOnLogin = "onLastLogout";
    };
    desktop.mouseActions.verticalScroll = "switchVirtualDesktop";
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

{ ... }:
{
  flake.modules.homeManager.kde-workspace = { pkgs, ... }: {
    # Theme packages backing the workspace options below.
    home.packages = with pkgs; [
      (catppuccin-kde.override {
        flavour = [ "mocha" ];
        accents = [ "teal" ];
        winDecStyles = [ "modern" ];
      })
      (catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "teal" ];
      })
      papirus-icon-theme
      graphite-cursors
    ];

    programs.plasma.workspace = {
      # Global Theme (look-and-feel package identifier)
      lookAndFeel = "Catppuccin-Mocha-Teal";
      # Plasma shell chrome (breeze-dark, etc.)
      widgetStyle = "catppuccin-mocha-teal-standard";
      # theme = "Catppuccin-Frappe-Blue";
      enableMiddleClickPaste = true;
      # Color scheme applied to all Qt/KDE windows
      colorScheme = "CatppuccinMochaTeal";

      # Cursor
      cursor = {
        theme = "graphite-dark";
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

    programs.plasma.input.keyboard = {
      numlockOnStartup = "on";
      layouts = [
        {
          layout = "in";
          variant = "eng";
        }
      ];
    };
  };
}
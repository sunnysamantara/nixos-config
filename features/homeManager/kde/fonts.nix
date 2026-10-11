{ ... }:
{
  flake.modules.homeManager.kde-fonts = { pkgs, ... }: {
    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [ "RobotoMono Nerd Font" "Noto Sans" ];
        serif = [ "RobotoMono Nerd Font" "Noto Serif" ];
        monospace = [ "RobotoMono Nerd Font Mono" "Noto Sans Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    home.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.roboto-mono
      nerd-fonts.fira-mono
      nerd-fonts.fira-code
    ];

    programs.plasma.fonts = {
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
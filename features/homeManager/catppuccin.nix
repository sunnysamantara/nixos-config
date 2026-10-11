{ inputs, ... }:
{
  flake.modules.homeManager.catppuccin = { ... }: {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];

    catppuccin = {
      enable = true;
      accent = "teal";
      flavor = "mocha";
      enableReleaseCheck = true;
      brave.enable = true; # inert until brave is installed
      firefox.enable = true; # inert until firefox is enabled
      obs.enable = true; # inert until obs-studio is enabled
      qt5ct = {
        enable = true; # inert until qt.enable
        assertPlatformTheme = true;
      };
      lazygit.enable = true;
      opencode.enable = true; # sets programs.opencode.tui.theme
      zsh-syntax-highlighting.enable = true;
    };
  };
}

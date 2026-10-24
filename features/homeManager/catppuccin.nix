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
      # OpenCode 2 moved tui.json to cli.json; catppuccin's module only sets
      # programs.opencode.tui, so we wire the theme up ourselves below.
      opencode.enable = false;
      zsh-syntax-highlighting.enable = true;
    };

    programs.opencode.cli.theme = {
      name = "catppuccin"; # mocha
      mode = "dark";
    };
  };
}

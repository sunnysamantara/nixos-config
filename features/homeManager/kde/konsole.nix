{ ... }:
{
  flake.modules.homeManager.kde-konsole = { pkgs, ... }: {
    programs.konsole = {
      enable = true;
      defaultProfile = "sunny";
      profiles.sunny = {
        command = "${pkgs.zsh}/bin/zsh";
        font = {
          name = "RobotoMono Nerd Font";
          size = 12;
        };
      };
    };
  };
}
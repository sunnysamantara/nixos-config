{pkgs, ...}: {
  imports = [
    # ./zsh.nix
  ];
  home.shell.enableNushellIntegration = true;
  programs.nushell = {
    enable = true;
    settings = {
      show_banner = "short";
    };
  };

  programs.konsole = {
    enable = true;
    defaultProfile = "sunny";

    profiles.sunny = {
      command = "${pkgs.nushell}/bin/nu";
      font = {
        name = "RobotoMono Nerd Font";
        size = 12;
      };
    };
  };

  programs.oh-my-posh = {
    enable = true;
    enableNushellIntegration = true;
    useTheme = "tokyo";
  };
}

{pkgs, ...}: {
  imports = [
    # ./zsh.nix
    ./oh-my-posh.nix
  ];
  home = {
    shell.enableNushellIntegration = true;
    sessionVariables = {
      SHELL = "${pkgs.nushell}/bin/nu";
    };
  };
  programs.nushell = {
    enable = true;
    settings = {
      show_banner = "short";
    };
    shellAliases = {
      btop = "btop --force-utf";
    };
  };
  # programs.tmux = {
  #   enable = true;
  #   # shell = "${pkgs.nushell}/bin/nu";
  #   keyMode = "vi";
  # };
  programs.konsole = {
    enable = true;
    defaultProfile = "sunny";
    profiles.sunny = {
      # command = "${pkgs.tmux}/bin/tmux";
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
    # useTheme = "easy-term";
    # configFile = "/home/sunny/.dotfile/user/catppuccin_custom.json";
  };
}

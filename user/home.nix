{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./neovim.nix
    ./plasma_manager.nix
    ./shell.nix
  ];
  # zsh changes has been moved to shell.nix
  home.packages = with pkgs; [
    fastfetch
    superfile
    nerd-fonts.roboto-mono
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.partitionmanager
    kdePackages.sddm-kcm
    kdePackages.wayland-protocols
    kdePackages.kde-gtk-config
    kdePackages.dolphin-plugins
    kdePackages.kdesdk-thumbnailers
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kdenetwork-filesharing
    kdePackages.kdeconnect-kde
    kdePackages.kamoso
    kdePackages.kimageformats
    kdePackages.qtimageformats
    kdePackages.ffmpegthumbs
    git-filter-repo
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };
  programs.obsidian.enable = true;
  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/sunny/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";
}

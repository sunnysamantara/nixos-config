{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./neovim.nix
    ./plasma_manager.nix
    ./shell.nix
    ./fastfetch.nix
    ./theme.nix
    ./desktop.nix
    ./zed.nix
    ./obsidian.nix
    # ./yubikey.nix
  ];
  # zsh changes has been moved to shell.nix
  home.packages =
    (with pkgs; [
      superfile
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.roboto-mono
      nerd-fonts.fira-mono
      nerd-fonts.fira-code
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
      # solaar
      brave
      zapzap
      notion-app
      # catppuccin-kde
      # catppuccin-gtk
      (catppuccin-kde.override {
        flavour = [ "mocha" ];
        accents = [ "teal" ];
        winDecStyles = [ "modern" ];
      })
      # catppuccin-cursors.mochaDark
      # kdePackages.qtstyleplugin-kvantum
      # (catppuccin-kvantum.override {
      #   accent = "sapphire";
      #   variant = "mocha";
      # })
      (catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "teal" ];
      })
      papirus-icon-theme
      graphite-cursors
      bitwarden-desktop
      appmenu-glib-translator
      # spyder
      # jetbrains.pycharm
      # python314Packages.spyder
      # python314Packages.spyder-kernels
      # python314Packages.jedi
      # python314Packages.matplotlib
      # python314Packages.numpy
      # python314Packages.pandas
      # python314Packages.seaborn
      conda
    ])
    ++ [
      # inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.kwin-effects-better-blur-dx.packages.${pkgs.system}.default
    ];
  # ++ [
  #   (let
  #     spyderExtraPackages = pkgs.python3.withPackages (ps:
  #       with ps; [
  #         pandas
  #         numpy
  #         matplotlib
  #         seaborn
  #       ]);
  #   in
  #     pkgs.symlinkJoin {
  #       name = "spyder-with-pkgs";
  #       paths = [pkgs.spyder];
  #       buildInputs = [pkgs.makeWrapper];
  #       postBuild = ''
  #         wrapProgram $out/bin/spyder \
  #           --prefix PYTHONPATH : "${spyderExtraPackages}/${spyderExtraPackages.sitePackages}"
  #       '';
  #     })
  # ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
      # allowUnfreePredicate = pkg:
      #   builtins.elem (lib.getName pkg) [
      #     "notion-app"
      #   ];
    };
  };

  /*
          gtk = {
      enable = true;
      theme = {
        name = "Catppuccin-Frappe-Standard-Blue-Dark";
        # package = pkgs.catppuccin-gtk.override {
        #   accents = ["blue"];
        #   variant = "frappe";
        # };
      };
    };
  */

  programs.lazygit = {
    enable = true;
    enableZshIntegration = true;
  };

  home.file = {
    ".face".source = ./garfield.png;
    ".face.icon".source = ./garfield.png;
  };

  /*
       gtk = {
      enable = true;

      # GTK3/GTK4 theme — Catppuccin Frappé, blue accent
      theme = {
        name = "Catppuccin-Frappe-Standard-Blue-Dark";
        package = pkgs.catppuccin-gtk;
        # package = pkgs.catppuccin-gtk.override {
        #   accents = ["blue"];
        #   size = "standard";
        #   variant = "frappe";
        #   # tweaks = []; # e.g. [ "rimless" "black" ] if you want those later
        # };
      };

      # Icon theme — match Plasma's iconTheme
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      # Cursor theme — match Plasma's workspace.cursor.theme (kept on Mocha, intentionally)
      cursorTheme = {
        name = "catppuccin-mocha-dark-cursors";
        package = pkgs.catppuccin-cursors.mochaDark;
        size = 23; # matches workspace.cursor.size
      };

      # gtk3.extraConfig = {
      #   gtk-application-prefer-dark-theme = true;
      # };
      # gtk4.extraConfig = {
      #   gtk-application-prefer-dark-theme = true;
      # };
    };
  */

  programs.git = {
    enable = true;
    lfs.enable = true;
    signing.format = "ssh";
  };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
      "github.com" = {
        HostName = "github.com";
        User = "sunny";
        IdentityFile = "~/.ssh/github";
        IdentitiesOnly = "yes";
      };
    };
  };

  # GTK4/libadwaita apps don't read gtk.theme.name directly — the module only
  # writes gtk-3.0/settings.ini + gtk-4.0/settings.ini. To actually get the
  # Catppuccin gtk.css applied to libadwaita apps you need to symlink the
  # theme's gtk-4.0 assets into ~/.config/gtk-4.0/ yourself:
  /*
       xdg.configFile = {
      "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
      "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
      "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
    };
  */
  # xdg.configFile."mimeapps.list".force = true;
  # gtk.gtk4.theme = config.gtk.theme;
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

  # HM will rename conflicting files to <name>.backup instead of erroring

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
    # EDITOR = "zeditor";
    GTK_MODULES = "appmenu-gtk-module";
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

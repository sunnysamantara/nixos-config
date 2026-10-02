{
  config,
  pkgs,
  inputs,
  ...
}: {
  # catppuccin.nvim = {
  #     enable = true;
  #     flavor = "mocha"; # latte, frappe, macchiato, mocha
  #     settings = {
  #       integrations = {
  #         lualine = true;
  #       };
  #     };
  #   };
  /*
  qt.kvantum.enable = true;
  */

  # gtk = {
  #   enable = true;
  #   # iconTheme = {
  #   #   name = "Papirus-Dark";
  #   #   # package = pkgs.papirus-icon-theme;
  #   # };
  #   cursorTheme = {
  #     name = "catppuccin-mocha-teal-cursors";
  #     package = pkgs.catppuccin-cursors.mochaTeal;
  #     size = 23;
  #   };
  # };

  # qt = {
  #   enable = true;
  #   platformTheme.name = "kde"; # use "kde" if on an older HM/plasma-manager pairing
  #   style.name = "kvantum";
  # };

  catppuccin = {
    enable = true;
    # gtk = {
    #   # enable = true;
    #   icon.enable = true;
    # };
    brave.enable = true;
    firefox.enable = true;
    lazygit.enable = true;
    # autoEnable = true;
    accent = "teal";
    flavor = "mocha";
    enableReleaseCheck = true;
    nvim = {
      enable = true;
      settings = {
        integrations = {
          lualine = true;
        };
      };
    };
    qt5ct = {
      enable = true;
      assertPlatformTheme = true;
    };
    # obsidian.enable = true;
    obs.enable = true;
    zsh-syntax-highlighting.enable = true;

    # kvantum = {
    #   enable = true;
    #   assertStyle = true;
    #   apply = true;
    # };
  };
  # xdg.configFile."gtk-3.0/settings.ini".force = true;
  # xdg.configFile."gtk-4.0/settings.ini".force = true;
  # xdg.configFile.".gtkrc-2.0".force = true;
  # home.file.".gtkrc-2.0".force = true;
}

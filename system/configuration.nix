{
  config,
  pkgs,
  inputs,
  ...
}:
let
  user = "sunny";
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./login.nix
    ./yubikey.nix
    ./virt.nix
  ];

  services = {
    fstrim.enable = true;
  };


  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libxcb
    xcb-util-cursor
    libx11
    libxi
    libsm
    libice
    libxkbcommon
    fontconfig
    freetype
    dbus
    glib
  ];

  # 1. Firewall Configuration for Packet / Quick Share
  networking.firewall = {
    enable = true;

    # Port 9300 is the standard static port for Packet / Quick Share receiving
    allowedTCPPorts = [
      9300

    ];

    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];

    # mDNS (Multicast DNS) uses UDP port 5353 for device discovery
    allowedUDPPorts = [ 5353 ];
  };
  programs.fuse.userAllowOther = true;
  #bluetooth



  # Enable networking
  networking.networkmanager.enable = true;
  #networking.useDHCP = true;
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # Enable the KDE Plasma Desktop Environment.

  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "in";
    variant = "eng";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.



  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sunny = {
    shell = pkgs.zsh;
    # shell = pkgs.nushell;
    ignoreShellProgramCheck = true;
    # openssh.authorizedKeys.keyFiles = [
    #   /home/sunny/.ssh/github
    # ];
    isNormalUser = true;
    description = "sunny";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      # bitwarden-desktop
      kdePackages.kdenlive
      obs-studio
      veracrypt
    ];
  };



  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  programs.partition-manager.enable = true;
  #   programs.kdeconnect.enable = true;
  security.polkit.enable = true;
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    lshw
    libheif
    kdePackages.kate
    kdePackages.kcalc
    # kdePackages.partitionmanager
    kdePackages.kdeconnect-kde
    kdePackages.sddm-kcm
    kdePackages.wayland-protocols
    kdePackages.kde-gtk-config
    kdePackages.dolphin-plugins
    kdePackages.kdesdk-thumbnailers
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kdenetwork-filesharing
    kdePackages.kamoso
    kdePackages.kimageformats
    kdePackages.qtimageformats
    kdePackages.ffmpegthumbs
    kdePackages.kate
    kdePackages.plasma-browser-integration
    libreoffice-qt-fresh
    qtscrcpy
    gimp2-with-plugins
    kdePackages.ktorrent
    nufraw-thumbnailer
    testdisk-qt
    kdePackages.qtmultimedia
    kdePackages.qtsvg
    kdePackages.layer-shell-qt
    haruna
    resvg
    # qpwgraph
    wayland-utils
    btop
    gdu
    devenv
    kdePackages.plasma-keyboard
    # wl-clipboard
    #neovim
    # git
    # nushell
    # maliit-framework
    # maliit-keyboard
    catppuccin-sddm-corners
  ];


  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bat.enable = true;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  services.solaar = {
    enable = true;
    # package = pkgs.solaar;
    window = "hide"; # Show the window on startup (show, *hide*, only [window only])
    # batteryIcons = "symbolic"; # Which battery icons to use (*regular*, symbolic, solaar)
  };
  };
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
  };


  # environment.sessionVariables = {
  # QT_IM_MODULE = "maliit";
  # MALIIT_PLUGINS_DIRS = "${pkgs.maliit-keyboard}/lib/maliit/plugins";
  # };

  # Forces the on-screen keyboard to appear even without a touchscreen
  # (default behavior is touch-only)
  # environment.sessionVariables = {
  #   KWIN_IM_SHOW_ALWAYS = "1";
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}

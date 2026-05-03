{
  config,
  pkgs,
  inputs,
  ...
}: let
  user = "sunny";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./grub.nix
    ./yubikey.nix
  ];
  #Nvidia

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  # Load nvidia driver for Xorg and Wayland
  # For offloading, `modesetting` is needed additionally,
  # otherwise the X-server will be running permanently on nvidia,
  # thus keeping the GPU always on (see `nvidia-smi`).
  services.xserver.videoDrivers = [
    "nvidia"
    "modesetting"
  ];

  services = {
    fstrim.enable = true;
  };
  programs.git = {
    enable = true;
    lfs.enable = true;
  };
  # environment.shells = [pkgs.nushell];
  #   environment.shells = with pkgs; [zsh];
  # environment.pathsToLink = ["/share/zsh"];
  #   users.defaultUserShell = pkgs.zsh;
  #   programs.zsh.enable = true;
  # environment.shells = with pkgs; [zsh];
  #   users.defaultUserShell = pkgs.zsh;
  #   programs.zsh.enable = true;
  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;
    prime = {
      sync.enable = true;
      # Make sure to use the correct Bus ID values for your system!
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [22];
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false; # disable password login (recommended)
      PermitRootLogin = "no"; # disable root login
    };
  };
  #bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages;
  boot.kernelParams = [
    "nvidia.Nvreg_PreserveVideoMemoryAllocations=1"
    "nvidia-drm.modeset=1"
  ];
  networking.hostName = "acer-aspire"; # Define your hostname.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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
  services.displayManager.sddm = {
    enable = true;
    autoNumlock = true;
    wayland.enable = true;
    settings.General.DisplayServer = "wayland";
    enableHidpi = true;
    settings.General.InputMethod = "maliit";
  };
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "in";
    variant = "eng";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sunny = {
    # shell = pkgs.zsh;
    # shell = pkgs.nushell;
    # ignoreShellProgramCheck = true;
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
      bitwarden-desktop
      kdePackages.kdenlive
      obs-studio
      veracrypt
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    lshw
    libheif
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
    kdePackages.kate
    libreoffice-qt-fresh
    qtscrcpy
    gimp2-with-plugins
    kdePackages.ktorrent
    nufraw-thumbnailer
    haruna
    resvg
    qpwgraph
    wayland-utils
    btop
    gdu
    # wl-clipboard
    #neovim
    # git
    # nushell
    maliit-framework
    maliit-keyboard
  ];
  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.discover
  ];
  programs.neovim = {
    enable = true;
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
    package = pkgs.solaar;
    window = "hide"; # Show the window on startup (show, *hide*, only [window only])
    batteryIcons = "regular"; # Which battery icons to use (*regular*, symbolic, solaar)
  };
  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Refer to the following link for more details:
    # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
    settings.auto-optimise-store = true; # nix-store --optimise
    # gc = {
    #   automatic = true;
    #   dates = "weekly";
    #   options = "--delete-older-than 15d";
    # };
  };
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 15d --keep 5";
    flake = "/home/sunny/.dotfile"; # sets NH_OS_FLAKE variable for you
  };

  environment.sessionVariables = {
    QT_IM_MODULE        = "maliit";
    MALIIT_PLUGINS_DIRS = "${pkgs.maliit-keyboard}/lib/maliit/plugins";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}

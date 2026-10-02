{
  config,
  pkgs,
  inputs,
  ...
}: let
  lobocorp-theme = pkgs.stdenvNoCC.mkDerivation {
    name = "lobo-grub-theme";
    src = inputs.lobo-grub-theme;

    installPhase = ''
      mkdir -p $out
      cp -r lobocorp/* $out/
    '';
  };
in {
  # Bootloader.
  boot.loader = {
    efi = {
      #canTouchEfiVariables = true;
      efiSysMountPoint = "/boot"; # ← use the same mount point here.
    };
    grub = {
      enable = true;
      efiSupport = true;
      useOSProber = true;
      efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
      device = "nodev";
      configurationLimit = 10;
      default = "saved";
      theme = lobocorp-theme;
      # dedsec-theme = {
      #   enable = true;
      #   style = "spyware";
      #   icon = "color";
      #   resolution = "1080p";
      # };
      # this has been moved to theme.nix
    };
    timeout = 5;
    # Disable systemd-boot
    systemd-boot.enable = false;
  };
  #   kdePackages.layer-shell-qt
  #   kdePackages.qtvirtualkeyboard
  # ];
  programs.qylock = {
    enable = true;
    theme = "sword";

    sddm.enable = true; # installs the theme + sets it active
    quickshell.enable = false; # Quickshell lockscreen doesn't work under KWin/Plasma anyway
  };
  services.displayManager.sddm = {
    enable = true;
    autoNumlock = true;
    wayland = {
      enable = true;
      compositor = "kwin";
    };
    theme = "sword";
    # extraPackages = with pkgs; [
    #   kdePackages.qtsvg
    #   kdePackages.qtmultimedia
    #   kdePackages.layer-shell-qt
    #   kdePackages.qtvirtualkeyboard
    # ];

    settings.General.DisplayServer = "wayland";
    enableHidpi = true;
    settings.General = {
      # InputMethod = "maliit";
      # GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
      # Numlock = "on";
    };

    # settings.Wayland = {
    #   CompositorCommand = "${pkgs.kdePackages.kwin}/bin/kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1 --inputmethod plasma-keyboard";
    # };
  };

}

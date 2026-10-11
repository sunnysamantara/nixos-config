{ ... }:
{
  flake.modules.nixos.sddm = { ... }: {
    services.displayManager.sddm = {
      enable = true;
      autoNumlock = true;
      wayland = {
        enable = true;
        compositor = "kwin";
      };
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
  };
}
{ ... }:
{
  flake.modules.homeManager.kde-apps = { pkgs, ... }: {
    home.packages = with pkgs.kdePackages; [
      kate
      kcalc
      partitionmanager
      sddm-kcm
      wayland-protocols
      kde-gtk-config
      dolphin-plugins
      kdesdk-thumbnailers
      kdegraphics-thumbnailers
      kdenetwork-filesharing
      kdeconnect-kde
      kamoso
      kimageformats
      qtimageformats
      ffmpegthumbs
      plasma-integration
      plasma-browser-integration
      plasma-keyboard
      layer-shell-qt
      qtmultimedia
      qtsvg
      ktorrent
    ];
  };
}
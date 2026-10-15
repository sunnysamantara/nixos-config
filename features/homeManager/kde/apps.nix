{ ... }:
{
  flake.modules.homeManager.kde-apps = { pkgs, ... }: {

    home.packages = with pkgs.kdePackages; [
      kate
      kcalc
      sddm-kcm
      partitionmanager
      wayland-protocols
      kde-gtk-config
      dolphin-plugins
      kdesdk-thumbnailers
      kdegraphics-thumbnailers
      kdenetwork-filesharing
      kdeconnect-kde
      kdenlive
      kamoso
      kimageformats
      qtimageformats
      ffmpegthumbs
      plasma-integration
      plasma-browser-integration
      plasma-keyboard
      layer-shell-qt
      qtmultimedia
      ktorrent
      qtsvg
      pkgs.haruna
    ];
  };
}
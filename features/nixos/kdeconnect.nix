{ ... }:
{
  flake.modules.nixos.kdeconnect = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.kdePackages.kdeconnect-kde ];

    # System services kdeconnect-kde (home-manager kde-apps) needs.
    services.avahi = {
      enable = true; # service discovery
      nssmdns4 = true;
      settings.publish = {
        "disable-publishing" = false;
        "disable-user-service-publishing" = false;
        "publish-addresses" = true;
      };
    };

    # Standard KDE Connect ports.
    networking.firewall.allowedTCPPortRanges = [
      { from = 1714; to = 1764; }
    ];
    networking.firewall.allowedUDPPortRanges = [
      { from = 1714; to = 1764; }
    ];
  };
}
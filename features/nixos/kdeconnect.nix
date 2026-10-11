{ ... }:
{
  flake.modules.nixos.kdeconnect = { ... }: {
    # System services kdeconnect-kde (home-manager kde-apps) needs.
    services.avahi = {
      enable = true; # service discovery
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        userServices = true;
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
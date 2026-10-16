{ ... }:
{
  flake.services.network-manager = { ... }: {
    networking.networkmanager.enable = true;
  };
}

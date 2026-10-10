{ ... }:
{
  hosts.acer-aspire = {
    # hostname defaults to the attribute name ("acer-aspire")
    system = "x86_64-linux";

    users = [ "sunny" ];

    # NixOS-side features, matching flake.modules.nixos.<name> in features/
    features = [

    ];

    extra = [
      ./_hardware.nix
      ./_pkg.nix
      {
        # Do not change stateVersion on an already-installed system.
        system.stateVersion = "25.11";
      }
    ];
  };
}

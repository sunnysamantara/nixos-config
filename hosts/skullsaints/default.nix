{ ... }:
{
  hosts.skullsaint = {
    # hostname defaults to the attribute name ("skullsaint")
    system = "x86_64-linux"; # use "aarch64-linux" for an ARM machine

    # sunny is shared with acer-aspire; route exists only on this host
    users = [
      "sunny"
      "route"
    ];

    # NixOS-side features, matching flake.modules.nixos.<name> in features/
    features = [ ];

    extra = [
      ./_hardware.nix # nixos-generate-config --show-hardware-config > _hardware.nix
      ./_pkg.nix
      {

        # sunny is a Nix trusted user on this host only.
        nix.settings.trusted-users = [
          "root"
          "sunny"
        ];
        system.stateVersion = "25.11";
      }
    ];
  };
}

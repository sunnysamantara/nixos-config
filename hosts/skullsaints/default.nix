{ inputs, ... }:
{
  hosts.skullsaint = {
    # hostname defaults to the attribute name ("skullsaint")
    system = "x86_64-linux"; # use "aarch64-linux" for an ARM machine

    # sunny is shared with acer-aspire; route exists only on this host
    users = [
      "route"
    ];

    # NixOS-side features, matching flake.modules.nixos.<name> in features/
    features = [ "disko" ];

    # System services, matching flake.services.<name> in services/
    services = [ "openssh" ];

    extra = [
      ./_disko.nix # declarative disk layout (nixos-anywhere; --disk main <dev> overrides)
      ./_hardware.nix # initrd modules + microcode only (no fileSystems — disko owns those)
      ./_pkg.nix
      {
        # core is a base feature; route owns the .dotfile flake on this host.
        core.dotfileUser = "route";
        system.stateVersion = "25.11";
      }
      {
        sops = {
          defaultSopsFile = inputs.nix-secrets + "/hosts/skullsaint.yaml";
          secrets."users/route" = { neededForUsers = true; };
          # secrets."root_password" = { neededForUsers = true; };
        };
        # users.users.root.hashedPasswordFile = config.sops.secrets."root_password".path;
      }
    ];
  };
}

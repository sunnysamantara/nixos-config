{ ... }:
{
  hosts.acer-aspire = {
    # hostname defaults to the attribute name ("acer-aspire")
    system = "x86_64-linux";

    users = [ "sunny" ];

    # NixOS-side features, matching flake.modules.nixos.<name> in features/
    features = [
      "sddm-sword"
      "kde"
      "kdeconnect"
      "catppuccin"
      "solaar"
    ];

    # System services, matching flake.services.<name> in services/
    services = [
      "audio"
      "bluetooth"
      "nvidia"
      "sddm"
      "virt-manager"
      "openssh"
      "network-manager"
    ];

    extra = [
      ./_hardware.nix
      ./_pkg.nix
      {
        # Do not change stateVersion on an already-installed system.
        system.stateVersion = "25.11";
        # core is a base feature; sunny owns the .dotfile flake on this host.
        core.dotfileUser = "sunny";
        # Host-specific SDDM background for catppuccin.sddm.
        catppuccin.sddm.background = ./resources/garfield.jpeg;
      }
    ];
  };
}

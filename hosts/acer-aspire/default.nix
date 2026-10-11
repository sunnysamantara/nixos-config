{ ... }:
{
  hosts.acer-aspire = {
    # hostname defaults to the attribute name ("acer-aspire")
    system = "x86_64-linux";

    users = [ "sunny" ];

    # NixOS-side features, matching flake.modules.nixos.<name> in features/
    features = [
      "virt-manager"
      "nvidia"
      "sddm"
      "sddm-sword"
      "kde"
      "kdeconnect"
      "openssh"
      "catppuccin"
      "audio"
      "bluetooth"
      "openlogi"
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

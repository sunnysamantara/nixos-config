{ ... }:
{
  flake.modules.nixos.virt-manager = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      virtio-win
      win-spice
      dnsmasq
      spice-protocol
      spice-gtk
      phodav
    ];

    virtualisation = {
      spiceUSBRedirection.enable = true;
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
          vhostUserPackages = with pkgs; [ virtiofsd ];
        };
      };
    };

    services.spice-vdagentd.enable = true;
    programs.dconf.enable = true;

    # Groups are declared empty; NixOS auto-fills `members` from each
    # user's `extraGroups` (e.g. "libvirtd"/"kvm" must be added to your user users/<username>/<username>.nix).
    users.groups = {
      libvirtd = { };
      kvm = { };
    };

    boot.kernelModules = [
      "kvm"
      "tun"
    ];
  };
}
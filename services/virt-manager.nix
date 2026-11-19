{ ... }:
{
  flake.services.virt-manager = { pkgs, ... }: {
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

    # `qemu.vhostUserPackages` only populates /var/lib/qemu/vhost-user metadata;
    # libvirt looks up the virtiofsd *binary* by searching PATH (`virtiofsd`, no
    # compiled-in path), and libvirtd's PATH is fixed in the NixOS module, so
    # without this a virtiofs share fails with "Cannot find 'virtiofsd' in PATH".
    # Windows guests need virtiofs: there is no 9p driver for Windows.
    systemd.services.libvirtd.path = [ pkgs.virtiofsd ];

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

{
  config,
  lib,
  pkgs,
  ...
}:

{
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

  users.groups = {
    libvirtd.members = [ "sunny" ];
    kvm.members = [ "sunny" ];
  };

  boot.kernelModules = [
    "kvm"
    "tun"
  ];
}

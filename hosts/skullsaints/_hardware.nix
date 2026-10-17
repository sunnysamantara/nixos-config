# Hand-maintained (NOT nixos-generate-config): fileSystems/swapDevices come
# from disko.nix, so only non-disk hardware bits live here.
{ config, lib, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Broad on purpose: covers NVMe/SATA/USB/UAS and virtio, so nixos-anywhere
  # can target real hardware or a VM without regenerating this file.
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "uas" "virtio_pci" "virtio_blk" "virtio_scsi" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

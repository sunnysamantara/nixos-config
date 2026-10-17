# Disk layout for skullsaint (deployed via nixos-anywhere).
# UEFI-only GPT: 2G ESP + 8G swap + 100G btrfs root (subvol @) + rest btrfs /home.
# The device below is a placeholder — nixos-anywhere overrides it:
#   nix run github:nix-community/nixos-anywhere -- --flake .#skullsaint --disk main /dev/nvme0n1 root@<ip>
{ ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "2G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0077" "dmask=0077" ];
          };
        };
        swap = {
          size = "8G";
          content.type = "swap";
        };
        root = {
          size = "100G";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes."@" = {
              mountpoint = "/";
              mountOptions = [ "compress=zstd" "noatime" ];
            };
          };
        };
        home = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "btrfs";
            mountpoint = "/home";
            mountOptions = [ "compress=zstd" "noatime" ];
          };
        };
      };
    };
  };
}

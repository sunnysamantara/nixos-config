# home-manager module, e.g. modules/home-manager/rclone.nix
{ config, pkgs, ... }:
{
  home.packages = [ pkgs.rclone ];

  systemd.user.services.rclone-onedrive = {
    Unit = {
      Description = "rclone mount for OneDrive";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/OneDrive";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount onedrive: %h/OneDrive \
          --config %h/.config/rclone/rclone.conf \
          --vfs-cache-mode writes \
          --dir-cache-time 1m \
          --poll-interval 15s
      '';
      ExecStop = "${pkgs.fuse}/bin/fusermount -u %h/OneDrive";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
}

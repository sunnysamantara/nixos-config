{ ... }:
{
  flake.services.sddm = { config, lib, ... }:
  let
    # Every user whose home-manager config sets profile.picture (the single
    # source of truth); route/skullsaint simply have none.
    withPicture = lib.filterAttrs (_: u: (u.profile.picture or null) != null)
      config.home-manager.users;
  in
  lib.mkMerge [
    {
      services.displayManager.sddm = {
        enable = true;
        autoNumlock = true;
        wayland = {
          enable = true;
          compositor = "kwin";
        };
        # extraPackages = with pkgs; [
        #   kdePackages.qtsvg
        #   kdePackages.qtmultimedia
        #   kdePackages.layer-shell-qt
        #   kdePackages.qtvirtualkeyboard
        # ];

        settings.General.DisplayServer = "wayland";
        enableHidpi = true;
        settings.General = {
          # InputMethod = "maliit";
          # GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
          # Numlock = "on";
        };

        # settings.Wayland = {
        #   CompositorCommand = "${pkgs.kdePackages.kwin}/bin/kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1 --inputmethod plasma-keyboard";
        # };
      };
    }

    # Avatars: configured only when at least one user set profile.picture.
    # services.accounts-daemon is intentionally NOT managed here — Plasma enables
    # it (plasma6.nix) and it owns the state dir. We create the dirs ourselves
    # because systemd-tmpfiles runs before the daemon starts.
    (lib.mkIf (withPicture != { }) {
      systemd.tmpfiles.rules = [
        "d /var/lib/AccountsService 0775 root root -"
        "d /var/lib/AccountsService/users 0700 root root -"
        "d /var/lib/AccountsService/icons 0755 root root -"
      ] ++ lib.flatten (lib.mapAttrsToList (user: u: [
        # L+ symlinks the world-readable store path so the sddm user can read the
        # icon despite 700 homes; f+ records it in AccountsService.
        "f+ /var/lib/AccountsService/users/${user}  0600 root root -  [User]\\nIcon=/var/lib/AccountsService/icons/${user}\\n"
        "L+ /var/lib/AccountsService/icons/${user}  -    -    -    -  ${u.profile.picture}"
        # FacesDir fallback keys on the .face.icon suffix.
        "L+ /var/lib/AccountsService/icons/${user}.face.icon  -    -    -    -  ${u.profile.picture}"
      ]) withPicture);

      # Belt-and-suspenders for greeter themes that use FacesDir directly.
      services.displayManager.sddm.settings.Theme.FacesDir =
        "/var/lib/AccountsService/icons";
    })
  ];
}

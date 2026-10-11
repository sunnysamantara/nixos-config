{ ... }:
{
  flake.modules.nixos.core = { config, lib, ... }:
  let
    cfg = config.core.dotfileUser;
  in
  {
    # No default on purpose: every host must name its dotfile owner.
    options.core.dotfileUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "User whose home contains the ~/.dotfile Nix flake (drives nh and trusted-users).";
    };

    config = {
      # Error-prone: a host that forgets this fails evaluation with a clear message.
      assertions = [
        {
          assertion = cfg != null;
          message = "core.dotfileUser is unset on this host; set it to the username whose home contains the .dotfile flake (host 'extra').";
        }
      ];

      nix.settings = lib.mkIf (cfg != null) {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true; # nix-store --optimise
        # "root" is the NixOS default trusted user; just add the dotfile owner.
        trusted-users = [ cfg ];
      };

      programs.nh = lib.mkIf (cfg != null) {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 15d --keep 5";
        flake = "${config.users.users.${cfg}.home}/.dotfile"; # home-derived, not hardcoded
      };
    };
  };
}
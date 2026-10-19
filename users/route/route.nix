{ inputs, config, ... }:
{
  # Account and home basics (isNormalUser, username, homeDirectory, _pkg.nix)
  # come automatically from core/users.nix. Only route-specific settings here.
  flake.modules.nixos.route = { config, ... }: {
    users.users.route = {
      isNormalUser = true;
      home = "/home/route";
      description = "Administrator";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      # Generate with: mkpasswd -m yescrypt
      # Replace before the first switch, or the account will not be able to log in.
      hashedPasswordFile = config.sops.secrets."users/route".path;
    };
  };

flake.modules.homeManager.route = { ... }: {
    imports = with config.flake.modules.homeManager; [
      ./_pkg.nix # skipped by import-tree (leading underscore), so imported here
      zsh
    ];

    # home.username / home.homeDirectory are derived from users.users.route.
    # Keep the value from your current home-manager config.
    home.stateVersion = "25.11";

    sops = {
      age.keyFile = "/home/route/.config/sops/age/keys.txt";
      defaultSopsFile = inputs.nix-secrets + "/users/route.yaml";
    };
  };
}

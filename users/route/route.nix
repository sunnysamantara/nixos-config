{ config, ... }:
{
  # Account and home basics (isNormalUser, username, homeDirectory, _pkg.nix)
  # come automatically from core/users.nix. Only route-specific settings here.
  flake.modules.nixos.route = { ... }: {
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
      hashedPassword = "$6$12wVJVGjT1QWyeXO$b4UONtpR0jEmqBhrqNJJx644GNfBqPXGzqZbMZtAjaUULYxdTzA63vWF9UgNncrloDcunTZ.rGhKESv6pu9un0";
    };
  };

  flake.modules.homeManager.route = { ... }: {
    imports = with config.flake.modules.homeManager; [
      
    ];

    # home.username / home.homeDirectory are derived from users.users.route.
    # Keep the value from your current home-manager config.
    home.stateVersion = "25.11";
  };
}

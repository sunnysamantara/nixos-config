{ config, ... }:
{
  # System side: the account itself (used by hosts that list "sunny").
  flake.modules.nixos.sunny = { pkgs, ... }: {
    users.users.sunny = {
      isNormalUser = true;
      home = "/home/sunny";
      description = "sunny";
      extraGroups = [
        "wheel"
        "networkmanager"
        "libvirtd" # needed for virt-manager/libvirt access
        "kvm" # needed for virt-manager/KVM device access
      ];
      # Keep your existing password setup here (hashedPassword / hashedPasswordFile).
      hashedPassword = "$6$12wVJVGjT1QWyeXO$b4UONtpR0jEmqBhrqNJJx644GNfBqPXGzqZbMZtAjaUULYxdTzA63vWF9UgNncrloDcunTZ.rGhKESv6pu9un0";
    };
  };

  # Home side: which home-manager features sunny gets.
  flake.modules.homeManager.sunny = { ... }: {
    imports = with config.flake.modules.homeManager; [
      ./_pkg.nix # skipped by import-tree (leading underscore), so imported here
      zsh
      fastfetch
      neovim
      oh-my-posh
      zed
      kde-all
      openssh
      git
      catppuccin
      obsidian
      opencode
      profile-picture
      devenv
    ];

    profile.picture = ./resources/icon.png;

    # home.username / home.homeDirectory are derived from users.users.sunny.
    # Keep the value from your current home-manager config.
    home.stateVersion = "25.11";
  };
}

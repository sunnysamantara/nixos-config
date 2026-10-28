{ inputs, config, ... }:
{
  # System side: the account itself (used by hosts that list "sunny").
  flake.modules.nixos.sunny = { config, pkgs, ... }: {
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
      hashedPasswordFile = config.sops.secrets."users/sunny".path;
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
      delta
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

    sops = {
      age.keyFile = "/home/sunny/.config/sops/age/keys.txt";
      defaultSopsFile = inputs.nix-secrets + "/users/sunny.yaml";

      # Gateway key for the local OmniRoute instance (services/omniroute.nix).
      # Decrypted at home-manager activation, read by OpenCode at runtime via
      # `{file:...}` — never inline the value (settings are a /nix/store file).
      secrets.omniroute_api_key = { };
    };
  };
}

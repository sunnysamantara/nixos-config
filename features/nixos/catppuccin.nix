{ inputs, ... }:
{
  flake.modules.nixos.catppuccin = { ... }: {
    imports = [ inputs.catppuccin.nixosModules.catppuccin ];

    catppuccin = {
      enable = true;
      accent = "teal";
      flavor = "mocha";
      enableReleaseCheck = true;
      cursors.enable = true;
      sddm = {
        enable = true;
        assertQt6Sddm = true;
        clockEnabled = false;
        userIcon = true;
        loginBackground = true;
        font = "RobotoMono Nerd Font";
        fontSize = "9";
      };
    };
  };
}

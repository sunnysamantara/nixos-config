{ inputs, ... }:
{
  flake.modules.nixos.sddm-sword = { ... }: {
    imports = [ inputs.qylock.nixosModules.default ];

    programs.qylock = {
      enable = true;
      theme = "sword";

      # SDDM theming is owned by catppuccin.sddm. qylock's sddm.enable defaults
      # to true (and would set sddm.theme = "sword"), so it must be false.
      sddm.enable = false;
      quickshell.enable = false; # Quickshell lockscreen doesn't work under KWin/Plasma anyway
    };

    # services.displayManager.sddm.theme = "sword"; # replaced by catppuccin.sddm
  };
}
{ ... }:
{
  flake.modules.homeManager.opencode = { pkgs, ... }: {
    programs.opencode = {
      enable = true;
      extraPackages = with pkgs; [
        ripgrep
        fd
        fzf
      ];
      # No `model` on purpose: pick one interactively with /models.
      # TUI theme is owned by the catppuccin integration (catppuccin.opencode).
    };
  };
}

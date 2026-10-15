{ ... }:
{
  flake.modules.homeManager.obsidian = { pkgs, inputs, ... }:
  let
    # Feature-local overlay: no global nixpkgs.overlays change.
    obsidianPkgs = import inputs.nixpkgs {
      inherit (pkgs.stdenv.hostPlatform) system;
      overlays = [ inputs.obsidian-extensions.overlays.default ];
    };
  in
  {
    programs.obsidian = {
      enable = true;

      vaults.notes.target = "Documents/Obsidian";

      defaultSettings = {
        communityPlugins = with obsidianPkgs.obsidianPlugins; [
          dataview
          obsidian-git
          obsidian-importer
          vim-yank-highlight
        ];

        themes = with obsidianPkgs.obsidianThemes; [
          catppuccin
        ];

        app = {
          alwaysUpdateLinks = true;
          spellcheck = true;
        };
      };
    };
  };
}
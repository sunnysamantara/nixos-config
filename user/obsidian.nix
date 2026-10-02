{
  config,
  pkgs,
  ...
}:
{
  programs.obsidian = {
    enable = true;

    vaults.notes.target = "Documents/Obsidian";

    defaultSettings = {
      communityPlugins = with pkgs.obsidianPlugins; [
        dataview
        obsidian-git
        obsidian-importer
        vim-yank-highlight
      ];

      themes = with pkgs.obsidianThemes; [
        catppuccin
      ];
      app = {
        alwaysUpdateLinks = true;
        spellcheck = true;
      };
    };
  };
}

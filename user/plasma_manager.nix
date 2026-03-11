{
  pkgs,
  ...
}: {
  # programs.konsole changes has been moved to shell.nix

  programs.plasma = {
    enable = true;
    overrideConfig = true;
    workspace.lookAndFeel = "org.kde.breezedark.desktop";
  };
}

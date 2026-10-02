{
  config,
  pkgs,
  ...
}: {
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
      background = "./garfield.jpeg";
      font = "RobotoMono Nerd Font";
      fontSize = "9";
    };
    # grub.enable = true;
  };
}

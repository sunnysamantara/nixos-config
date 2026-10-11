{ ... }:
{
  flake.modules.homeManager.kde-krunner = { ... }: {
    programs.plasma.krunner = {
      shortcuts.launch = "Meta";
      position = "center";
      activateWhenTypingOnDesktop = true;
      historyBehavior = "enableAutoComplete";
    };
  };
}
{ ... }:
{
  flake.modules.homeManager.kde-power = { ... }: {
    programs.plasma.powerdevil = {
      AC = {
        autoSuspend = {
          action = "hibernate";
          idleTimeout = 1800;
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 1680;
        };
        powerButtonAction = "turnOffScreen";
        turnOffDisplay.idleTimeoutWhenLocked = 60;
        powerProfile = "balanced";
      };
      battery = {
        autoSuspend = {
          action = "hibernate";
          idleTimeout = 900;
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 780;
        };
        powerButtonAction = "shutDown";
        turnOffDisplay.idleTimeoutWhenLocked = 30;
        powerProfile = "powerSaving";
        whenLaptopLidClosed = "hibernate";
      };
      batteryLevels.lowLevel = 20;
      lowBattery = {
        autoSuspend = {
          action = "hibernate";
          idleTimeout = 300;
        };
        dimDisplay = {
          enable = true;
          idleTimeout = 180;
        };
        powerButtonAction = "shutDown";
        powerProfile = "powerSaving";
        turnOffDisplay.idleTimeout = 180;
        whenLaptopLidClosed = "shutDown";
      };
    };
  };
}
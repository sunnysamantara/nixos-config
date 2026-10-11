{ ... }:
{
  flake.modules.nixos.bluetooth = { ... }: {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true; # battery charge reporting
          FastConnectable = true; # faster device connects
          Enable = "Source,Sink,Media,Socket"; # BT audio codecs
        };
        Policy = {
          AutoEnable = true;
        };
      };
    };
  };
}

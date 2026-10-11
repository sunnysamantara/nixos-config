{ ... }:
{
  flake.modules.nixos.audio = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.qpwgraph ];

    services.pulseaudio.enable = false;
    security.rtkit.enable = true; # realtime kit, used by PipeWire
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}

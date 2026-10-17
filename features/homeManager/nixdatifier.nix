{ ... }:
{
  flake.modules.homeManager.nixdatifier = { pkgs, inputs, config, lib, ... }:
    let
      plasmoidId = "org.muddyblack.nixosGenerationExplorer";
      nixdatifierPkgs = inputs.nixdatifier.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages = [
        nixdatifierPkgs.default
        nixdatifierPkgs.nixdatifier
      ];

      home.file.".config/autostart/nixdatifier.desktop" = {
        text = ''
          [Desktop Entry]
          Type=Application
          Exec=${nixdatifierPkgs.nixdatifier}/bin/nixdatifier --background
          Icon=${plasmoidId}
          Name=Nixdatifier
          Comment=NixOS generations, diffs, flake updates and dev environments
          Categories=System;Utility;
          StartupNotify=false
          X-GNOME-Autostart-enabled=true
        '';
      };
    };
}

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

      home.activation.nixdatifierFlakePath = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="${config.home.homeDirectory}/.config/nixdatifier/standalone.json"
        tmp="$cfg.tmp.$$"
        ${pkgs.jq}/bin/jq --arg p "${config.home.homeDirectory}/.dotfile" \
          '. + {flakePath: $p}' <(if [ -s "$cfg" ]; then cat "$cfg"; else echo '{}'; fi) > "$tmp" \
          && ${pkgs.coreutils}/bin/install -m 644 "$tmp" "$cfg"
        ${pkgs.coreutils}/bin/rm -f "$tmp"
      '';

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

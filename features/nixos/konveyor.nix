{ inputs, ... }:
{
  # Thin adapter: Konveyor's generic NixOS module now owns the system side
  # (package, plugin/QML env, optional Plasma wiring). This repo only opts in
  # via its existing feature name so hosts keep using `features = [ ... "konveyor" ]`.
  flake.modules.nixos.konveyor = {
    imports = [ inputs.konveyor.nixosModules.default ];
    programs.konveyor.enable = true;
  };
}

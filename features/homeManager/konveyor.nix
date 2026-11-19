{ inputs, ... }:
{
  # Thin adapter: the fork's Home Manager module owns widgets, user services,
  # desktop entries and one-time config seeding. `programs.konveyor.enable`
  # follows the NixOS side's `enableWidgets`, so hosts without the KWin effect
  # (e.g. the router) keep a stock Plasma session.
  flake.modules.homeManager.konveyor = {
    imports = [ inputs.konveyor.homeManagerModules.default ];
  };
}

{ lib, ... }:
{
  # The `services/` registry. Distinct namespace from `flake.modules.nixos.*`
  # (features) so a name can never be used as both a feature and a service:
  # features resolve via `flake.modules.nixos.<name>`, services via
  # `flake.services.<name>`. Hosts opt in with `services = [ ... ]`.
  options.flake.services = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = { };
    description = "System service modules, referenced by hosts via `services = [ ... ]`.";
  };
}

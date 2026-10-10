# AGENTS.md

NixOS flake (flake-parts + import-tree). Branch `nix-dendrite` is a WIP
re-architecture from the old `system/`+`user/` layout; expect missing modules.

## Commands
- Evaluate everything: `nix flake check`
- Build a host: `nixos-rebuild build --flake .#<host>` (or `.#<host>` on the machine)
- Apply: `sudo nixos-rebuild switch --flake .#<host>`
- Update inputs: `nix flake update`
- Some packages need: `NIXPKGS_ALLOW_INSECURE=1` (e.g. `NIXPKGS_ALLOW_INSECURE=1 sudo -E nixos-rebuild switch --flake . --impure`)

There is no test suite; `nix flake check` is the verification step.

## Architecture
- `flake.nix` imports `core/ features/ users/ hosts/` via `import-tree`.
- Every file is auto-imported EXCEPT names starting with `_` (e.g.
  `_pkg.nix`, `_hardware.nix`). Import those explicitly.
- Feature/user files register modules as
  `flake.modules.nixos.<name>` and `flake.modules.homeManager.<name>`.
- `core/hosts.nix` defines the `hosts.<name>` registry. Each entry becomes
  `nixosConfigurations.<name>` and composes:
  `users` -> nixos + homeManager modules, `features` -> nixos modules,
  `extra` -> raw NixOS modules (hardware file, `_pkg.nix`, stateVersion).

## Hosts
- Host key is the `hosts.<attr>` name, NOT the directory name.
  `hosts/skullsaints/default.nix` defines `hosts.skullsaint` -> `.#skullsaint`.
- `acer-aspire` (x86_64-linux), `skullsaint` (trusted-users sunny).

## Gotchas
- `core/hosts.nix` `getMod` throws if a referenced user/feature module is
  not defined. The tree is currently incomplete (missing `shell`/`zsh`/`kde`
  homeManager modules, empty `nvidia.nix`, empty `route.nix`) so it will not
  evaluate until those are added.
- `nixpkgs.config.allowUnfree = true` and home-manager `useGlobalPkgs` /
  `useUserPackages` are set globally; don't re-enable per host.
- Do NOT change `system.stateVersion` / `home.stateVersion` (`"25.11"`).
- `README.md` is stale (old layout commands, standalone home-manager) and
  contains plaintext secrets. Trust `flake.nix`/`core/`, not the README.
- `.gitignore`'s `system/hardware-configuration.nix` path is stale; hardware
  files now live at `hosts/<host>/_hardware.nix` and are committed.

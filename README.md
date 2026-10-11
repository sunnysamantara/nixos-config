# nixos-config

NixOS configuration managed as a flake (flake-parts + import-tree). Branch
`nix-dendrite` re-architects the old `system/`+`user/` layout into
`core/ features/ users/ hosts/`.

- `core/` – host registry wiring (`hosts.nix`), flake module registration.
- `features/` – reusable NixOS (`nixos/`) and home-manager (`homeManager/`) modules.
- `users/` – per-user config (accounts + home-manager feature opt-in).
- `hosts/` – per-machine config (`acer-aspire`, `skullsaint`).
- Two package sets in every module: `pkgs` (nixos-unstable) and
  `stable-pkgs` (nixos-26.05).
- New `.nix` files must be `git add`-ed before the flake can see them, and
  `nix flake check` is the verification step (no test suite).

## First-time setup

```sh
ssh-keygen -t ed25519 -C "github" -f ~/.ssh/github
ssh-add ~/.ssh/github
git remote set-url origin git@github.com:sunnysamantara/nixos-config.git
ssh -T git@github.com
```

## Everyday commands (host: `acer-aspire`)

| Task                                   | Command                                                        |
| -------------------------------------- | -------------------------------------------------------------- |
| Check the whole flake evaluates        | `nix flake check`                                              |
| Apply a config change (system + home-manager) | `sudo nixos-rebuild switch --flake .#acer-aspire`        |
| Build without applying                 | `nixos-rebuild build --flake .#acer-aspire`                    |
| Reinstall bootloader on first install  | `sudo nixos-rebuild switch --install-bootloader --flake .#acer-aspire` |
| Update all inputs, then apply          | `nix flake update` then `sudo nixos-rebuild switch --flake .#acer-aspire` |
| Update only some inputs                | `nix flake update home-manager nixpkgs nixpkgs-stable`          |
| Inspect host config                     | `nix eval --json .#nixosConfigurations.acer-aspire.config.system.path` |

> On the machine itself, `.#<host>` resolves from the repo dir; use the host
> attribute name (`skullsaint` for `hosts/skullsaints`).

## Upgrading home-manager programs & settings

home-manager runs *as a NixOS module* here — there is no separate
`home-manager switch`. Editing `features/homeManager/*.nix` or `users/*/` and
then rebuilding the host rebuilds and activates every user's home config.

```sh
nix flake update                 # bump home-manager, nixpkgs, nixpkgs-stable, nvf…
sudo nixos-rebuild switch --flake .#acer-aspire
```

If a package is marked insecure:

```sh
NIXPKGS_ALLOW_INSECURE=1 sudo -E nixos-rebuild switch --flake . --impure
```

## Useful `nh` commands

`nh` (nix-community/nh) replaces `nixos-rebuild`/`nix flake update` with a
single wrapper. Install it via `pkgs.nh` (or `feature nixos`), then:

| Task                                       | Command                                            |
| ------------------------------------------ | -------------------------------------------------- |
| Build + apply config (system + home-manager) | `nh os switch . -H acer-aspire`                  |
| Build without applying                     | `nh os build . -H acer-aspire`                     |
| Update inputs + verify it builds           | `nh update`                                        |
| Update + apply in one go                   | `nh update --switch` (if supported)                |
| Old-generation / store GC                  | `sudo nh clean all --keep-since 15d --keep 5`      |
| Same, keeping direnv roots                 | `sudo nh clean --no-direnv`                        |

`nh` can auto-resolve the flake/host if `programs.nh.flake = "/home/sunny/homeserver"`
is set on the machine — then just `nh os switch`.

## Other useful nix commands

```sh
sudo nix-collect-garbage -d                 # delete old generations + GC
sudo nix-store --optimise                   # hard-link dedup in the store
sudo nix-store --verify --check-contents --repair
nix flake show                               # list all flake outputs
nix-channel --list                           # (legacy channels; this repo is flake-only)
```

## Resources

- awesome-nix (curated Nix resources): https://github.com/nix-community/awesome-nix
- nix.dev (official tutorials): https://nix.dev
- Packages / options search: https://search.nixos.org
- NixOS Wiki: https://wiki.nixos.org
- home-manager options reference: https://nix-community.github.io/home-manager/options.xhtml
- NixOS & Flakes Book (practical guide): https://nixos-and-flakes.thiscute.world
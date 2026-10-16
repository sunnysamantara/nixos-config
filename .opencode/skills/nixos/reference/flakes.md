# Nix flakes

Flakes are the input/output schema for reproducible Nix projects. They pin all dependencies via `flake.lock`, eliminating reliance on mutable channels or `NIX_PATH`. Still marked experimental in upstream Nix, but universally adopted in practice.

## Flake anatomy

```nix
{
  description = "My project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in {
        packages.default = pkgs.hello;
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.go pkgs.gopls ];
        };
      }
    );
}
```

Three top-level attributes:
- **`description`**: human-readable string
- **`inputs`**: dependency declarations (pinned in `flake.lock`)
- **`outputs`**: function from resolved inputs to Nix values

## Input types

| URL scheme | Example | Notes |
| :--- | :--- | :--- |
| `github:` | `github:NixOS/nixpkgs/nixos-26.05` | GitHub repo at branch/tag/rev |
| `gitlab:` | `gitlab:user/repo` | GitLab repo |
| `git+https:` | `git+https://example.com/repo.git` | Generic git |
| `path:` | `path:./subdir` | Local path (for monorepos) |
| `sourcehut:` | `sourcehut:~user/repo` | SourceHut repo |

## The `follows` keyword

Ensures multiple inputs use the same nixpkgs instance:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  home-manager.url = "github:nix-community/home-manager/release-26.05";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";
  sops-nix.url = "github:Mic92/sops-nix";
  sops-nix.inputs.nixpkgs.follows = "nixpkgs";
};
```

Without `follows`, each input fetches its own nixpkgs, wasting eval time and disk space.

## Common output types

```nix
outputs = { self, nixpkgs, ... }: {
  # NixOS system configurations
  nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ ./configuration.nix ];
  };

  # nix-darwin configurations
  darwinConfigurations.mymac = nix-darwin.lib.darwinSystem {
    modules = [ ./darwin.nix ];
  };

  # Home Manager configurations (standalone)
  homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    modules = [ ./home.nix ];
  };

  # Packages
  packages.x86_64-linux.default = ...;

  # Dev shells
  devShells.x86_64-linux.default = ...;

  # Overlays
  overlays.default = final: prev: { ... };

  # NixOS modules
  nixosModules.default = import ./module.nix;
};
```

## flake-parts

A framework for writing flakes using the NixOS module system. Reduces boilerplate and enables module composition:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { pkgs, ... }: {
        packages.default = pkgs.hello;
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.nil pkgs.nixpkgs-fmt ];
        };
      };
    };
}
```

flake-parts modules can be shared across projects. See [flake.parts](https://flake.parts/) for the module catalog.

## Dev shells

```nix
devShells.default = pkgs.mkShell {
  packages = [ pkgs.go pkgs.gopls pkgs.golangci-lint ];

  shellHook = ''
    echo "Go dev environment loaded"
  '';

  env = {
    GOPATH = "$PWD/.go";
  };
};
```

Enter with `nix develop`. Combine with [direnv](https://github.com/nix-community/nix-direnv) for automatic shell activation.

## Ecosystem tools

### crane (Rust builds)

Builds Rust projects incrementally by splitting dependency and source compilation:

```nix
crane.url = "github:ipetkov/crane";
# Use crane.mkCraneLib to get buildDepsOnly, buildPackage, etc.
```

### dream2nix (multi-language)

Automates reproducible packaging for multiple language ecosystems. Under active refactoring (drv-parts). Integrates as a flake-parts module.

### flake-utils

Lightweight utility for iterating over systems. Simpler than flake-parts but less composable:

```nix
flake-utils.lib.eachDefaultSystem (system: { ... })
```

### nixos-unified

Unifies NixOS + nix-darwin + Home Manager in a single flake with consistent structure. See [nixos-unified](https://github.com/srid/nixos-unified).

## Nix CLI commands

| Command | Purpose |
| :--- | :--- |
| `nix flake update` | Update all inputs to latest |
| `nix flake update nixpkgs` | Update a single input |
| `nix flake lock --update-input nixpkgs` | Same, deprecated spelling -- prefer `nix flake update nixpkgs` |
| `nix flake show` | Display flake outputs |
| `nix flake check` | Evaluate and check all outputs |
| `nix flake metadata` | Show input revisions and lock info |
| `nix build .#package` | Build a specific output |
| `nix develop` | Enter dev shell |
| `nix run .#program` | Build and run |

## Nix vs Lix

Both are supported. Lix is a community fork of Nix (diverged from 2.18) focused on stability and contributor friendliness. Key points:

- Lix is fully compatible with existing Nix configurations and flakes.
- nix-darwin and NixOS both support Lix as an alternative.
- Switch with `nix.package = pkgs.lix` in your system config.
- Lix uses Meson for its build system and plans gradual Rust adoption.
- The installer you use does not lock you in; `nix.package` controls which implementation runs.

## Release channels and branches

### NixOS releases

| Channel | Branch | Use |
| :--- | :--- | :--- |
| `nixos-26.05` | `release-26.05` | Current stable (support until December 2026) |
| `nixos-26.11` | `release-26.11` (once cut) | Next stable: releases November 2026 as "Zokor"; `master` tracks it until then |
| `nixos-unstable` | `master` | Rolling, latest packages |

Security note: branches past their support window (e.g. `nixos-25.11`, EOL June 2026) stop receiving security backports -- do not deploy them.

### nixpkgs channels (for nix-darwin / standalone)

| Channel | Use |
| :--- | :--- |
| `nixpkgs-26.05-darwin` | Stable packages for macOS |
| `nixpkgs-unstable` | Latest packages, all platforms |

### Flake input conventions

```nix
# Stable (NixOS)
nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

# Stable (nix-darwin)
nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

# Latest
nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
```

For nix-darwin with the stable branch, also use `nix-darwin/nix-darwin-26.05`.

## Best practices

- Always use `follows` for nixpkgs across all inputs (collapses duplicate package sets and keeps one reviewed nixpkgs).
- Commit `flake.lock` to version control.
- Use `nix flake check` in CI.
- Avoid `builtins.fetchTarball` or `builtins.fetchGit` without hashes (breaks reproducibility).
- Prefer `nix develop` over `nix-shell` for flake-based projects.
- Review `nix flake update` diffs before applying to production systems -- especially **owner/repo renames** in the lock (repository takeover vector) and inputs you did not touch appearing.
- Use a consistent nixpkgs branch across NixOS/nix-darwin/Home Manager (align via `follows`).

### Supply chain

- **Evaluation executes input code**: running any `nix build`/`nix eval`/`nix flake check` runs the Nix code of *every* input, before any build sandbox exists. Treat adding an input as adding a dependency you execute -- pin third-party inputs to an exact `rev` or tag rather than a floating branch, and drop inputs you no longer use.
- Substituters are trust: a cache can serve the bytes your builds install, so only add caches whose `trusted-public-keys` you recognize. If a flake's `nixConfig` asks to add substituters, verify the keys before accepting the prompt.
- Fixed-output hashes are integrity boundaries: generate them yourself (`nix hash`, prefetch) instead of copying from untrusted snippets, and never commit placeholder hashes (`""`, `lib.fakeHash`).

## Key references

- [Nix flakes wiki](https://wiki.nixos.org/wiki/Flake)
- [nix.dev best practices](https://nix.dev/guides/best-practices)
- [flake-parts documentation](https://flake.parts/)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- [crane](https://github.com/ipetkov/crane)
- [dream2nix](https://dream2nix.dev/)
- [Lix](https://lix.systems/)

# AGENTS.md

NixOS flake (flake-parts + import-tree). Branch `nix-dendrite` re-architects the
old `system/`+`user/` layout into `core/ features/ services/ users/ hosts/`. The
legacy `user/` and `system/` dirs are stale leftovers — ignore them, do not edit.

`features/` and `services/` are **disjoint by construction**: features live in
`flake.modules.nixos.<name>`, services in `flake.services.<name>`. A name can
never be both — listing a service under `features` (or a feature under
`services`) fails evaluation.

## Commands
- Evaluate everything: `nix flake check` (no test suite; this is it)
- Build a host: `nixos-rebuild build --flake .#<host>` (or `.#<host>` on the machine)
- Apply: `sudo nixos-rebuild switch --flake .#<host>`
- Update inputs: `nix flake update`
- Some packages may still need: `NIXPKGS_ALLOW_INSECURE=1` (e.g. `NIXPKGS_ALLOW_INSECURE=1 sudo -E nixos-rebuild switch --flake . --impure`).
  Unfree does NOT need an env var any more: `nixpkgs.config.allowUnfree = true`
  is set in the base feature (`features/nixos/core.nix`), so plain
  `sudo nixos-rebuild switch --flake .#<host>` evaluates.
- Stage new `.nix` files (`git add`, even `-N`) and `nix flake check` before
  committing: the flake ignores untracked files.
- Edit a secret with a **key file** (no YubiKey): `scripts/sops-edit <file>`,
  e.g. `scripts/sops-edit users/sunny.yaml` (user key),
  `scripts/sops-edit hosts/acer-aspire.yaml` (host key, sudo).
  It is a thin wrapper around
  `SOPS_AGE_KEY_FILE=<key> sops <file>`; see "Secrets management".

## Architecture
- `flake.nix` imports `core/ features/ services/ users/ hosts/` via `import-tree`;
  every file is auto-imported EXCEPT names starting with `_` (`_pkg.nix`,
  `_hardware.nix`, `_disko.nix`) — import those explicitly (both
  `users/*/<name>.nix` import `./_pkg.nix`). This is required for host-local
  *raw NixOS modules*: an auto-imported file is treated as a flake-parts module,
  so a `disko.devices`/`fileSystems` definition must live in a `_`-prefixed file
  listed in the host's `extra`.
- Feature/user files register `flake.modules.nixos.<name>` and
  `flake.modules.homeManager.<name>`. Service files register `flake.services.<name>`.
- `core/services.nix` declares the `flake.services` registry (`lazyAttrsOf
  deferredModule`) — a namespace separate from `flake.modules.nixos`, which is
  what makes features/services mutually exclusive.
- `core/hosts.nix` registry `hosts.<name>` → `nixosConfigurations.<name>`,
  composing: `users` (nixos + homeManager modules), `features` (nixos modules via
  `getMod "nixos"`), `services` (via `getService`), `baseFeatures = [ "core" "internationalization" ]` and `baseServices = [ "boot" ]` (every host), `extra` (raw NixOS modules: hardware,
  `_pkg.nix`, stateVersion). The two resolvers throw readable errors for unknown
  or mis-categorised names.
- Users opt into homeManager features via `imports` in their `<name>.nix`
  (`zsh fastfetch neovim oh-my-posh zed delta kde-all git catppuccin obsidian
  opencode devenv`); hosts
  opt into nixos features via `features = [...]` and system services via
  `services = [...]`.
- Feature/service files are themselves flake-parts modules: a top-level fn only
  receives flake-parts args (`config`/`inputs`/`lib`), NOT `pkgs`. Take
  `pkgs`/`inputs` as INNER args of the registered module
  (`flake.modules.homeManager.x = { pkgs, inputs, ... }:` or
  `flake.services.x = { pkgs, ... }:`), as in `zsh.nix`/`boot.nix`/`services/openssh.nix`.
- Two package sets, both module args everywhere (NixOS `specialArgs` + HM
  `extraSpecialArgs` in `core/hosts.nix`): `pkgs` = nixos-unstable,
  `stable-pkgs` = nixos-26.05, both `allowUnfree`. NOTE: those only cover the
  module args — the NixOS system pkgs itself is configured separately by
  `nixpkgs.config.allowUnfree = true` in `features/nixos/core.nix` (missing it
  used to make every `switch` fail on unfree `nvidia-x11` in pure eval).

- Custom packages live under `pkgs/<name>/default.nix` and are exposed via
  `overlays/default.nix` (applied to both `pkgs` and `stable-pkgs` in
  `core/hosts.nix`), so consumers can use `pkgs.<name>`. AppImages use
  `appimageTools.wrapType2` for proper desktop entry/icon integration.
- `scripts/sops-edit` — shell helper (not a Nix module; import-tree only picks
  up `.nix`) that opens a `secrets/` file with the matching **age key file**:
  `users/*` → `~/.config/sops/age/keys.txt`, `hosts/*`+`common.yaml` →
  `/var/lib/sops-nix/key.txt` through sudo, then chowns the file back.
  The host key only decrypts *this* host's file (+ `common.yaml`); another
  host's file needs that host's key or the YubiKey.
  Overrides: `SOPS_USER_KEY_FILE`, `SOPS_HOST_KEY_FILE`, `SOPS_EDIT_BIN`.
- `secrets/` is a private git repo with encrypted secrets. It's referenced as
  a flake input and used by the `sops` base feature. It is nested in the main
  repo as a git submodule (the editing working copy), but eval reads the
  `nix-secrets` GitHub input, never the working tree. See "Secrets
  management" below.

## Secrets management
- Secrets live in `secrets/` — a **private git repo** (remote:
  `git@github.com:sunnysamantara/nix-secrets.git`) nested inside the main flake
  repo. It is a git submodule (the editing working copy). Eval does NOT read
  it from the working tree — the flake input is the GitHub repo itself:
  `inputs.nix-secrets.url = "git+ssh://git@github.com/sunnysamantara/nix-secrets"`,
  locked by rev in `flake.lock`.
- **Hard rule: NEVER push any code to the secrets repo.** Only encrypted
  secret files (`.yaml`, `.json`, etc. encrypted with sops) are allowed.
  No source code, no configuration files, no plaintext files.
- **Key model:**
  - User age keys at `~/.config/sops/age/keys.txt` — per-user, decrypt own
    private secrets (home-manager). **Must be owned by and readable for the
    user** (`0600`): home-manager's sops-nix is a *user* systemd service, so a
    root-owned key file silently breaks HM activation. If it is root-owned:
    `sudo chown sunny:users ~/.config/sops/age/keys.txt`.
  - Host machine keys at `/var/lib/sops-nix/key.txt` — per-host, generated by
    sops-nix (`age.generateKey = true`), decrypt host secrets at boot. Root-only
    (`0600 root:root`), so decrypting/editing host files needs `sudo`.
  - YubiKey (PIV slot 9a) — universal key, can decrypt ALL secrets. Used for
    emergency access, initial setup, and as a master key. Not tied to any user.
- **Editing with a key file (default workflow, no YubiKey):** every operation
  is `SOPS_AGE_KEY_FILE=<key file> sops <file>`; the recipients still come
  from `.sops.yaml`. `scripts/sops-edit` picks the key automatically:
  ```
  scripts/sops-edit users/sunny.yaml        # ~/.config/sops/age/keys.txt
  scripts/sops-edit hosts/acer-aspire.yaml  # /var/lib/sops-nix/key.txt, sudo + chown back
  scripts/sops-edit common.yaml             # host keys, sudo + chown back
  ```
  Equivalent raw commands (`sops` is not installed system-wide, hence
  `nix-shell -p sops`):
  ```
  # user file, as yourself
  SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
    nix-shell -p sops --run 'sops users/sunny.yaml'
  # host file, as root (root-only key), then hand the file back
  sudo env SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt \
    nix-shell -p sops --run 'sops hosts/acer-aspire.yaml'
  sudo chown "$(id -un):$(id -gn)" hosts/acer-aspire.yaml
  ```
  Sanity-check that a key file matches `.sops.yaml`:
  `sudo age-keygen -y /var/lib/sops-nix/key.txt` must print the `host_acer`
  recipient (`age19pw07…`), and
  `age-keygen -y ~/.config/sops/age/keys.txt` the `user_sunny` one
  (`age1nzaag…`). Env overrides: `SOPS_USER_KEY_FILE`, `SOPS_HOST_KEY_FILE`,
  `SOPS_EDIT_BIN` (path to an existing `sops`).
- **Secret files** (in `secrets/`):
  - `common.yaml` — shared across all hosts.
  - `hosts/<host>.yaml` — host-only secrets (`users/<user>` password hashes +
    `root_password`, all `neededForUsers = true`). Each host file contains a
    `users` map with one entry per user on that host, e.g.:
    ```yaml
    users:
      sunny: < ---password-hash--- >
    root_password: < ---password-hash--- >
    ```
  - `users/<user>.yaml` — user's personal secrets, decrypted by user's age
    key in home-manager session.
  - OmniRoute (`services/omniroute.nix`): server-side keys live as an
    `omniroute:` map in `hosts/<host>.yaml` —
    `omniroute/{jwt_secret,api_key_secret,ws_bridge_secret,initial_password}`
    (declared by the service, rendered into
    `/run/secrets/rendered/omniroute.env` via
    `sops.templates."omniroute.env"`); the OpenCode gateway key is
    `omniroute_api_key` in `users/sunny.yaml` (declared in
    `users/sunny/sunny.nix`) and read at runtime through OpenCode's
    `{file:...}` substitution. Declaring a key that is absent from the sops
    file aborts activation, so only hosts that enable the service carry the
    `omniroute:` map.
- **sops-nix** is a base feature (`baseFeatures` in `core/hosts.nix`). Each
  host overrides `sops.defaultSopsFile` to point at its own host-specific file.
- **Adding a new secret:**
  1. Edit the appropriate file in `secrets/`.
  2. Open it with the matching key file (see above):
     `scripts/sops-edit <file>` — or the raw
     `SOPS_AGE_KEY_FILE=<key> nix-shell -p sops --run "sops <file>"`
     from inside `secrets/`.
  3. Commit and push to the private repo.
  4. In the main repo: `nix flake update nix-secrets` (relocks the input to
     the pushed rev — eval uses the GitHub repo, NOT the local working tree).
  5. Commit the updated `flake.lock` and rebuild/deploy the affected host(s).
- **YubiKey setup:** `age-plugin-yubikey` generates the age identity on the
  YubiKey. The public key is added to ALL creation rules in `.sops.yaml`.
  Routine edits do **not** need it — use the key files
  (`scripts/sops-edit`). The YubiKey is the universal recovery key: emergency
  access and initial setup, not normal boot/host decryption.
- **Gotcha:** Host machine keys must be pre-generated and installed before
  first boot. If a host key is lost, use the YubiKey to decrypt and re-encrypt
  secrets, then generate a new host key.

## Hosts
- Host key is `hosts.<attr>`, NOT the directory name: `hosts/skullsaints/default.nix`
  defines `hosts.skullsaint` → `.#skullsaint`.
- `acer-aspire` (x86_64-linux): features sddm-sword (qylock, inert — see under
  Catppuccin below), kde, kdeconnect, catppuccin, solaar; services audio,
  bluetooth, nvidia (Intel+NVIDIA prime sync; bus IDs are hardware-specific),
  sddm, virt-manager, openssh, network-manager, yubikey, omniroute. Evaluates. Its `extra` overrides
  `catppuccin.sddm.background` with
  the host-local `hosts/acer-aspire/resources/garfield.jpeg`.
- `skullsaint` (x86_64-linux, users sunny+route): **router machine** — will do
  WAN↔LAN routing, NAT, DHCP/DNS, so it must NOT run NetworkManager (client-side
  tool that fights static router interfaces). Ethernet takes over; no Plasma/KDE.
  Disk layout is **disko-declarative**: `hosts/skullsaints/_disko.nix` (2G ESP
  /boot, 8G swap, 100G btrfs root subvol `@`, rest btrfs /home; device
  placeholder `/dev/nvme0n1`, overridden at deploy with
  `nixos-anywhere --disk main <dev>`), and `_hardware.nix` holds only the
  non-disk bits (initrd modules incl. `virtio_*` for VM targets, kvm-intel,
  Intel microcode) — it is hand-maintained, never `nixos-generate-config`.
  The old committed `_hardware.nix` was a byte-copy of acer-aspire's (same
  UUIDs) until replaced by this. Deploy (DESTROYS the target disk):
  `nix run github:nix-community/nixos-anywhere -- --flake .#skullsaint --disk
  main /dev/nvme0n1 root@<ip>`; the target disk must be ≥ ~110G (fixed 100G
  root partition). features disko; services openssh (plus `boot` via
  `baseServices`).

## Current features / users
- homeManager: `zsh` (shell + SHELL env), `fastfetch` (logo commented out),
  `neovim` (nvf via `inputs.nvf.homeManagerModules.default` + `programs.neovim`),
  `oh-my-posh` (custom prompt; glyphs via JSON `\uXXXX` trick, schema URL kept on
  `main`), `zed` (zed-editor + marksman/harper/nixd LSPs, nixfmt; registers
  `agent_servers.opencode` as a `type = "custom"` ACP agent running
  `${pkgs.opencode}/bin/opencode acp` — the key matches Zed's ACP-registry entry
  so the HM settings merge overrides its `type = "registry"`, which otherwise
  downloads a generic-linux opencode that cannot run on NixOS; note the store
  path is `pkgs.opencode` (bundles ripgrep) not the `programs.opencode`
  extraPackages wrapper, so fd/fzf are not injected), `delta` (`features/homeManager/delta.nix`;
  Zed Industries' standalone Delta AI/agent editor, installed from the official
  `inputs.delta` flake — `github:zed-industries/delta-nix`, with
  `inputs.nixpkgs.follows = "nixpkgs"` so its proprietary Linux binary links the
  host graphics stack (`/run/opengl-driver`); `home.packages` only, no options,
  ships its own `.desktop`/icons; upstream sets `allowUnfree` internally, so no
  repo-side unfree wiring; `x86_64-linux`/`aarch64-linux` only; pulled in by
  `sunny`, not `route`), `git`
  (`programs.git` — lfs, SSH signing via `~/.ssh/github.pub` + `signByDefault`,
  user/init settings, `git-filter-repo` in `home.packages`; also `programs.lazygit`
  + zsh integration, merged in from the old `lazygit` feature), `catppuccin` (imports
  `inputs.catppuccin.homeModules.catppuccin`; global mocha/teal + brave/firefox/
  obs/qt5ct/lazygit/zsh-syntax-highlighting toggles (opencode handled separately,
  see its bullet); neovim theming lives in
  `neovim.nix` via nvf `vim.theme = "catppuccin"`), `obsidian`
  (`programs.obsidian`; vault `notes` → `Documents/Obsidian`; community plugins
  `dataview`/`obsidian-git`/`obsidian-importer`/`vim-yank-highlight` + `catppuccin`
  theme, all from `pkgs.obsidianPlugins`/`pkgs.obsidianThemes` supplied by a
  **feature-local** `import inputs.nixpkgs { overlays = [ inputs.obsidian-extensions.overlays.default ]; }`
  — no global overlay), `opencode` (`programs.opencode` minimal: enable +
  `extraPackages` ripgrep/fd/fzf; NO `model` set so you pick one via `/models`;
  OpenCode 2 theme is owned by the `catppuccin` feature: `catppuccin.opencode`
  is disabled (it only writes the old `tui.theme`) and `programs.opencode.cli.theme`
  is set to `{ name = "catppuccin"; mode = "dark"; }`; also registers the
  self-hosted OmniRoute gateway as a static `provider.omniroute`
  (`npm = "@ai-sdk/openai-compatible"`, `baseURL =
  http://127.0.0.1:20128/v1`, curated `auto/*` models) whose
  `options.apiKey = "{file:${config.sops.secrets.omniroute_api_key.path}}"` is
  resolved at runtime — see the OmniRoute section), `devenv` (`programs.direnv`
  + `nix-direnv` + `programs.devenv`; import-only like the simple features),
  `profile-picture` (option
  `profile.picture` (path, default null) → `~/.face` + `~/.face.icon`; the
  NixOS-side AccountsService/FacesDir wiring lives in the `sddm` feature),
  `nixdatifier` (`features/homeManager/nixdatifier.nix`; import-only like the other
  simple features — no options; installs the Plasma 6 plasmoid
  (`inputs.nixdatifier.packages.<sys>.default`) and the standalone tray app
  (`inputs.nixdatifier.packages.<sys>.nixdatifier`) and writes
  `.config/autostart/nixdatifier.desktop` running `nixdatifier --background`;
  widget/tray icon colours and all other settings are configured via the widget's
  own right-click → Configure / the app UI, not declaratively; pulled in by
  `kde-all`, so KDE users get it without a separate import).
- homeManager `kde/` family (dir features/homeManager/kde): `kde` (core — imports
  `inputs.plasma-manager.homeModules.plasma-manager`, plasma.enable), `kde-desktop`
  (panels/systray; `systemTray.items.hidden = [ "indicator-solaar" ]` keeps the
  Solaar StatusNotifier icon in the popup, not the bar — unmatched id when
  solaar is off, otherwise it keeps the icon out of the bar), `kde-workspace` (theming pkgs: catppuccin-kde/gtk, papirus,
  graphite-cursors; look&feel, keyboard layout in/eng via
  `programs.plasma.input.keyboard`), `kde-kwin` (effects/titlebar/shortcuts +
  `inputs.kwin-effects-better-blur-dx` pkg), `kde-power` (powerdevil),
  `kde-session` (restore/kscreenlocker/mouse), `kde-krunner`, `kde-fonts`
  (fonts.fontconfig + nerd/noto fonts),   `kde-apps` (ALL KDE user packages in
  `home.packages`), `kde-konsole` (programs.konsole). `kde-all` imports
  the whole family in one go, **plus `nixdatifier`** (top-level HM feature, see
  its own bullet). No Plasma/KDE packages at the system level — it's
  all HM (plasma-manager generates `plasma-workspace/kwin` config from HM).
- nixos features: `core` (base feature: `nixpkgs.config.allowUnfree = true`,
  `nix.settings.experimental-features`,
  `auto-optimise-store`, `nix.settings.trusted-users` = root + `core.dotfileUser`,
  `programs.nh` with `flake` derived from that user's home — no hardcoded
  path/username; every host must set `core.dotfileUser` in its `extra`,
  otherwise eval fails; and `programs.nix-ld.enable = true` — FHS dynamic
  linker + the nix-ld default library set, so generic dynamically-linked
  binaries (Zed's self-downloaded ACP agents and LSPs, npm globals, tarballs)
  run instead of failing on stub-ld. Base feature → all hosts; the `NIX_LD*`
  vars are session-scoped, so a relogin is needed after enabling), `sddm-sword` (qylock module via
  `inputs.qylock.nixosModules.default`; `sddm.enable = false` so theming is owned
  by `catppuccin`; acer-aspire only), `kde` (minimal:
  `services.desktopManager.plasma6.enable` + Discover excluded; acer-aspire only),
  `kdeconnect` (avahi via `settings.publish` + firewall 1714-1764; acer-aspire only), `catppuccin`
  (imports `inputs.catppuccin.nixosModules.catppuccin`; global mocha/teal,
  cursors + SDDM theme; acer-aspire only), `solaar` (native `programs.solaar`:
  `enable` + `userService.enable`/`window = "hide"`; **enabled on acer-aspire**
  — Solaar and OpenLogi fight over HID++ receiver access, so only one may be
  active), `openlogi` (local-first Logitech
  HID++ manager; **no longer a flake input** — the upstream module is inlined
  against `pkgs.openlogi`, the cached cache.nixos.org build, so there is no Rust
  compile; installs the package (CLI + `openlogi-gui` + `.desktop`),
  `70-openlogi.rules` via `services.udev.packages`, and
  `systemd.user.services.openlogi-agent` on `graphical-session.target`;
  **kept but not enabled on any host** — displaced by `solaar` on acer-aspire),
  `internationalization` (base feature:
  `time.timeZone = "Asia/Kolkata"`, `i18n.defaultLocale = "en_IN"` + `LC_*`
  extraSettings; keyboard layout lives in the HM `kde-workspace` feature),
  `disko` (import-only: imports `inputs.disko.nixosModules.disko` so a host's
  `extra` can carry `disko.devices.*`; enabled on skullsaint only — hosts
  without a disko config get no effect from it).
- services (nixos, `flake.services.<name>`), all moved out of `features/nixos/`:
  `boot` (base service: GRUB/EFI loader with OS-prober, `configurationLimit 10`,
  `default = "saved"`, systemd-boot disabled; every host via `baseServices`),
  `openssh` (`services/openssh.nix`; `services.openssh` password auth off, root
  login off, firewall TCP 22; also a separate HM client feature
  `features/homeManager/openssh.nix`), `audio` (PipeWire: alsa 32-bit/pulse/jack
  + `security.rtkit`; `qpwgraph` in `environment.systemPackages`; acer-aspire),
  `bluetooth` (bluez via `hardware.bluetooth`: Experimental/FastConnectable/
  AutoEnable + `Enable = "Source,Sink,Media,Socket"`; acer-aspire), `nvidia`
  (Intel+NVIDIA prime sync; bus IDs are hardware-specific; acer-aspire), `sddm`
  (SDDM/Wayland/KWin + the avatar wiring — for every user whose HM
  `profile.picture` is set it writes `/var/lib/AccountsService/{users,icons}/<user>`
  via `systemd.tmpfiles` (`d` creates the state dirs, `L+` symlinks the
  world-readable store path so `sddm` can read it despite 700 homes, plus a
  `<user>.face.icon` symlink) and sets SDDM `Theme.FacesDir`; all of it is
  `lib.mkIf (withPicture != { })`, and `services.accounts-daemon` is **not**
  managed here since Plasma enables it; acer-aspire), `virt-manager` (libvirtd/
  kvm users opt in via `extraGroups`; acer-aspire), `network-manager`
  (`networking.networkmanager.enable`; acer-aspire only), `yubikey`
  (`services/pcscd` + `programs.yubikey-manager`, `security.pam.u2f` with
  `/run/secrets/u2f_keys`; per-service PAM rules: `login` requires password then
  YubiKey, `sudo`/`kde` accept either; acer-aspire), `omniroute`
  (`services/omniroute.nix`; OmniRoute AI gateway as a rootful-podman OCI
  container, `docker.io/diegosouzapw/omniroute:3.8.52`, named volume
  `omniroute-data:/app/data`, published on `127.0.0.1:20128` only ⇒ no firewall
  change; `REQUIRE_API_KEY=true` + `OMNIROUTE_MEMORY_MB=4096`; server secrets
  from the host sops file via `sops.templates."omniroute.env"`; acer-aspire —
  see the OmniRoute section).
- users: `sunny` (both hosts; extraGroups wheel/networkmanager/libvirtd/kvm),
  `route` (skullsaint only); packages: sunny `pkgs.lshw`, route `stable-pkgs.wget`,
  acer-aspire `pkgs.lshw`, skullsaints `stable-pkgs.lshw`.

## OmniRoute (local AI gateway)
OmniRoute (https://github.com/diegosouzapw/OmniRoute) is a self-hosted,
OpenAI-compatible AI router. It is deployed as `services/omniroute.nix`
(`flake.services.omniroute`), enabled on **acer-aspire only** — no Nix
packaging, just the official OCI image under rootful podman.

- Image `docker.io/diegosouzapw/omniroute:3.8.52` (pinned SemVer; bump
  deliberately and re-`switch`, `pull = "missing"` re-pulls a new tag, not a
  moved one). Published on `127.0.0.1:20128` only ⇒ loopback, no firewall
  change; reach the dashboard/API at `http://127.0.0.1:20128`.
- State lives in the podman **named volume** `omniroute-data` (`/app/data`:
  SQLite DB, provider credentials, `server.env`). It is NOT in the Nix store
  and NOT in sops — back it up with
  `sudo podman volume export omniroute-data > omniroute-data.tar`.
- Podman here is **rootful** (`virtualisation.oci-containers` default user is
  `root`), so every CLI call needs `sudo`: `sudo podman ps`,
  `sudo podman logs omniroute`, `sudo podman exec omniroute …`. The published
  port is a host-side bind on `127.0.0.1`, so user processes (OpenCode) still
  reach it without sudo.
- Env: `REQUIRE_API_KEY=true` (so `/v1` needs a gateway key; upstream default
  is false), `OMNIROUTE_MEMORY_MB=4096` (the image's 1024 MB floor is a
  dashboard-only floor — the launcher appends `--max-old-space-size`), plus
  `--stop-timeout=40` for graceful SSE drain.
- Server secrets are **host-scoped** (`secrets/hosts/acer-aspire.yaml`,
  `omniroute:` map, YubiKey/host key only): `jwt_secret`, `api_key_secret`,
  `ws_bridge_secret`, `initial_password`. `services/omniroute.nix` declares
  them and renders `sops.templates."omniroute.env"` (root, 0400) at
  `/run/secrets/rendered/omniroute.env`, passed to podman via
  `environmentFiles`. Missing keys abort activation (sops-nix semantics).
- `INITIAL_PASSWORD` is the dashboard password applied while none is saved in
  the DB (no onboarding wizard); after first start change it in the UI. It does
  not re-apply on later boots.
- OpenCode side: `features/homeManager/opencode.nix` adds a
  `provider.omniroute` (`npm = "@ai-sdk/openai-compatible"`, `name =
  "OmniRoute"`, `baseURL = http://127.0.0.1:20128/v1`). Models are fetched
  dynamically from OmniRoute's `/v1/models` endpoint at runtime (depends on
  providers configured in the dashboard). The live catalogue can be inspected
  via `curl` or with `sudo podman exec omniroute omniroute setup-opencode --dry-run`,
  or use the upstream `@omniroute/opencode-plugin` if you want live model discovery
  behavior. No default `model` is set; `/models` → `omniroute/auto` is the sane pick.
- `options.apiKey` must stay `"{file:${config.sops.secrets.omniroute_api_key.path}}"`:
  `programs.opencode.settings` is rendered to a **world-readable** store file
  (`~/.config/opencode/opencode.json` → `/nix/store/…-opencode.json`), so
  inlining the key would leak it; sops-nix decrypts at HM activation (path is
  a placeholder at eval time) and OpenCode resolves `{file:…}` at runtime.
  Fallback if OpenCode rejects the file ref: `opencode auth login` →
  `omniroute` (stored in `~/.local/share/opencode/auth.json`).

### Manual steps (you must do these, in order)
Everything below needs a private age key file (or the YubiKey) — the agent
cannot do it. Do NOT `switch` before steps 1–3 are done:
`services/omniroute.nix` declares host secrets **and** the HM side declares
`omniroute_api_key`, so system *and* home-manager activation abort while they
are missing.

- [ ] **0. One-time: make your user key usable** — `~/.config/sops/age/keys.txt`
  is currently `0600 root:root`, and home-manager's sops-nix runs as a user
  service, so it cannot read it:
  ```
  sudo chown sunny:users ~/.config/sops/age/keys.txt
  chmod 600 ~/.config/sops/age/keys.txt
  ```
  Verify both key files match `.sops.yaml` (user → `age1nzaag…`,
  host → `age19pw07…`):
  ```
  nix-shell -p age --run 'age-keygen -y ~/.config/sops/age/keys.txt'
  sudo nix-shell -p age --run 'age-keygen -y /var/lib/sops-nix/key.txt'
  ```
- [ ] **1. Add the server secrets** to the host file — it is encrypted to
  `host_acer` + `yubikey`, so open it with the **host key file**
  (`/var/lib/sops-nix/key.txt`, root-only; the helper wraps sudo and restores
  the file's ownership). Generate strong values, e.g.
  `openssl rand -hex 32` for each `*_secret`, plus a dashboard password.
  ```
  cd /home/sunny/homeserver
  scripts/sops-edit hosts/acer-aspire.yaml
  # raw equivalent:
  # sudo env SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt \
  #   nix-shell -p sops --run 'sops hosts/acer-aspire.yaml'
  # sudo chown "$(id -un):$(id -gn)" hosts/acer-aspire.yaml
  ```
  Add (top level, next to `users:`/`root_password:`):
  ```yaml
  omniroute:
      jwt_secret: <openssl rand -hex 32>
      api_key_secret: <openssl rand -hex 32>
      ws_bridge_secret: <openssl rand -hex 32>
      initial_password: <dashboard password>
  ```
- [ ] **2. Bootstrap the user file** (`sops.secrets.omniroute_api_key` is
  already declared in `users/sunny/sunny.nix`, so `users/sunny.yaml` must be a
  real encrypted file — today it is comment-only). It is encrypted to
  `user_sunny` + `yubikey`, so open it with the **user key file**. The real
  key does not exist until step 5, so put a placeholder; OpenCode returns 401
  until it is replaced.
  ```
  cd /home/sunny/homeserver
  scripts/sops-edit users/sunny.yaml
  # raw equivalent (as yourself, no sudo):
  # SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  #   nix-shell -p sops --run 'sops users/sunny.yaml'
  ```
  add `omniroute_api_key: PENDING`.
- [ ] **3. Push + relock the flake input, then deploy** — eval reads GitHub,
  not this working tree:
  ```
  cd /home/sunny/homeserver/secrets && git add -A && git commit -m "omniroute secrets" && git push
  cd /home/sunny/homeserver && nix flake update nix-secrets && git add flake.lock
  git add services/omniroute.nix scripts/sops-edit && nix flake check
  sudo nixos-rebuild switch --flake .#acer-aspire
  sudo systemctl status podman-omniroute.service
  curl -sf -o /dev/null -w '%{http_code}\n' http://127.0.0.1:20128/   # 200/302/401
  ```
- [ ] **4. Configure providers + mint a gateway key** at
  `http://127.0.0.1:20128` (log in with `initial_password` from step 1): add
  your upstream provider credentials (this also populates the model
  catalogue), then create a gateway API key (Endpoints / API keys) and copy
  the `sk-…` value. `curl http://127.0.0.1:20128/v1/models -H "Authorization:
  Bearer <key>"` should list models.
- [ ] **5. Replace the placeholder** with the real key (user key file only,
  no YubiKey needed):
  ```
  cd /home/sunny/homeserver
  scripts/sops-edit users/sunny.yaml   # omniroute_api_key: sk-…
  cd secrets && git add -A && git commit -m "omniroute gateway key" && git push
  cd /home/sunny/homeserver && nix flake update nix-secrets
  sudo nixos-rebuild switch --flake .#acer-aspire
  ```
  HM activation writes `~/.config/sops-nix/secrets/omniroute_api_key` (0400).
- [ ] **6. Verify OpenCode**: `opencode models | grep '^omniroute/'` lists the
  curated models at least; `opencode` → `/models` → `omniroute/auto`; ask a
  question and check `sudo podman logs --tail 20 omniroute` shows the request.
  Optional: regenerate the exact catalogue into the static list —
  `sudo podman exec omniroute omniroute setup-opencode --dry-run` prints the JSON.

Rotation: re-`sops` the value (same key-file command), push,
`nix flake update nix-secrets`, `switch`
(`sudo systemctl restart podman-omniroute` if the env-file change alone does not
restart it — the unit is restarted on `switch` anyway). Changing
`jwt_secret`/`api_key_secret` invalidates existing dashboard sessions and
gateway keys.

## Gotchas
- Untracked `.nix` files are NOT part of the flake source: run `git add` (even
  `-N`) before `nix flake check`/eval can see them.
- `home.username` / `home.homeDirectory` are derived from `users.users.<name>.home`;
  set `home` on the account, don't set them inside home-manager (same-priority
  conflict with HM's common.nix).
- `nix flake check` prints `warning: unknown flake output 'modules'` and
  `warning: unknown flake output 'services'` — harmless (flake-parts
  `modules` flakeModule + the repo's own `flake.services` registry); silence via
  `touchup` if desired.
- Do NOT change `system.stateVersion` / `home.stateVersion` (`"25.11"`).
- README.md has been rewritten for the flake layout (stale notes about the old
  single-file `configuration.nix` / standalone home-manager are gone). Trust
  flake/core. `user/` + `system/` dirs are stale leftovers grandfathered in.
- `.gitignore`'s `system/hardware-configuration.nix` is stale; hardware lives at
  `hosts/<host>/_hardware.nix` and is committed.
- `/home/sunny/homeserver` is the flake you edit (new `core/ features/ services/`
  layout, branch `nix-dendrite`). `/home/sunny/.dotfile` is on branch `main`
  with the new layout (commit `b8bc765`), so it's the same layout as `homeserver`
  now. `programs.nh.flake` points at `${home}/.dotfile`. Prefer `sudo nixos-rebuild
  switch --flake /home/sunny/homeserver#<host>` when in doubt.
- **Diagnose "did it actually build/apply?"** `nixos-rebuild` can evaluate
  cleanly and still leave the old generation active if the new store path was
  never realized. Compare the running system with what the current flake wants:
  ```
  readlink -f /run/current-system
  cd /home/sunny/homeserver && nix eval --raw --impure --expr \
    'let f = builtins.getFlake (toString ./.); in f.nixosConfigurations.<host>.config.system.build.toplevel.outPath'
  ```
  If the evaluated path does not exist in the store (`ls -ld <path>`), nothing
  was built/applied — run the `switch`. `ls -ld /nix/var/nix/profiles/system-*-link`
  shows the timestamps of the generations that actually exist.
- `build-vm` output is separate: `result -> …-nixos-vm` plus
  `hosts/acer-aspire.qcow2`. A host-side `switch` does not update a booted VM,
  and a switch done inside the VM does not update the host.
- Secrets are in a separate private repo (`secrets/` submodule). The flake input
  `inputs.nix-secrets` is `git+ssh://git@github.com/sunnysamantara/nix-secrets`
  — the **invoking user** must be able to fetch it over SSH (private repo):
  a key with repo access in `~/.ssh/` + github.com in `known_hosts`. Plain
  `nixos-rebuild switch --flake .#host` evals as you (key in your `~/.ssh`);
  `sudo nixos-rebuild`/`sudo nh` evals as root → root needs its own key in
  `/root/.ssh/` (read-only deploy key from the nix-secrets repo, installed as
  `/root/.ssh/id_ed25519` + `/root/.ssh/known_hosts`; generated 2026-10-20,
  pubkey must be added as a read-only deploy key on GitHub). Same-key copies
  are safe: use the read-only deploy key everywhere, never an account key.
- Host machine keys at `/var/lib/sops-nix/key.txt` must exist before first
  boot. sops-nix generates them if missing, but then the public key won't
  match `.sops.yaml`.
- **Never push code to the secrets repo.** Only encrypted secret files.
- Root passwords are stored as `root_password` in `secrets/hosts/<host>.yaml`,
  decrypted at boot via `neededForUsers = true` and set as
  `users.users.root.hashedPasswordFile`. Hosts without a root password
  explicitly lock root with `users.users.root.hashedPassword = "!"`.

## NixOS best practices (this repo)
- Compose, don't override: `allowUnfree`, `useGlobalPkgs`/`useUserPackages`,
  `baseFeatures`/`baseServices` are global — don't re-set per host/user.
- Keep features reusable: no hardcoded usernames; grant access via a user's
  `extraGroups` or a host's `extra`. NixOS auto-derives `users.groups.*.members`
  from `extraGroups`.
- Stability-sensitive packages → `stable-pkgs.X`; newest → `pkgs.X`.
- Never hand-edit `_hardware.nix`; regenerate with `nixos-generate-config`
  (exception: skullsaint's is hand-maintained — it carries only non-disk bits,
  filesystems come from `_disko.nix`).
- Pull external modules (e.g. nvf) via the flake's `homeManagerModules.default` /
  `nixosModules.default` (or `nixosModules.disko`) in the feature file; capture
  `inputs` in the OUTER flake-parts function (see `features/nixos/disko.nix`).
- Keep per-user/per-host package lists in `_pkg.nix` files, not inline modules.
- Run `nix flake check` after changes (validates both hosts).

## Regression audit (nix-dendrite migration)
Findings from back-testing the flake against legacy `system/`+`user/` and from
isolated module evals. Learn these before adding features.

### Fixed in-tree
- `features/nixos/sops.nix` set `sops.defaultSopsFile = …/common.yaml` at default
  priority, conflicting (same priority, different value) with each host's
  `sops.defaultSopsFile` override in `extra` — full toplevel eval died with
  "option `sops.defaultSopsFile' has conflicting definition values". It stayed
  hidden while the old `path:` secret input failed earlier (NAR mismatch), and
  `nix flake check` doesn't force the sops options. Fix: wrapped in
  `lib.mkDefault` so the host file wins (base = common.yaml fallback).
- The `nvidia` service (unfree `nvidia-x11` via `hardware.graphics`) made
  pure-mode eval — i.e. every plain `sudo nixos-rebuild switch --flake .#<host>` —
  fail with `Refusing to evaluate package 'nvidia-x11'`, so no new system
  generation was ever created ("nothing changes"). Cause: `allowUnfree` was set
  only on the `pkgs`/`stable-pkgs` module args in `core/hosts.nix`, never on the
  NixOS system pkgs. Fix: `nixpkgs.config.allowUnfree = true` in
  `features/nixos/core.nix`. No env var / `--impure` needed for unfree any more.
- `features/nixos/core.nix`: `trusted-users` hardcoded `"sunny"` → now `[ cfg ]`
  (`cfg = core.dotfileUser`). Regression test: eval the module with
  `dotfileUser = "route"` and confirm `nix.settings.trusted-users` and
  `programs.nh.flake` agree (`["root","route"]` + `/home/route/.dotfile`).
- `features/homeManager/kde/kwin.nix`: `pkgs.system` → `pkgs.stdenv.hostPlatform.system`
  (old form warns `'system' has been renamed…` and is slated for removal).
- `zsh.nix` used to run `eval "$(devenv hook zsh)"` with no `devenv` installed
  (error on every shell start). Fixed by adding the `devenv` HM feature
  (`programs.direnv` + `nix-direnv` + `programs.devenv`) and dropping the hook
  from `zsh.nix`; `sunny` imports `devenv`.
- `features/homeManager/zed.nix`: nixd `expr`s hardcoded `/home/sunny` +
  `nixosConfigurations.acer-aspire` and pointed at a nonexistent
  `homeConfigurations` output. Now uses `${config.home.homeDirectory}` +
  `${osConfig.networking.hostName}` (`osConfig` is injected by HM when it runs as
  a NixOS module — see `common.nix`). There is no `home_manager.expr` because the
  flake exports no `homeConfigurations`; add that output if you ever want it.
- Zed's OpenCode External Agent (ACP) died with `Server exited with status 127`
  / `Could not start dynamically linked executable: …/external_agents/registry/
  opencode/…` — Zed's ACP registry downloads a generic-linux opencode that
  needs `/lib64/ld-linux-x86-64.so.2`, which is NixOS's stub-ld. Fix: re-enable
  `programs.nix-ld` (base `core` feature) so `/lib64/…` resolves, and register
  `agent_servers.opencode` as `type = "custom"` on `${pkgs.opencode}/bin/opencode
  acp` in `features/homeManager/zed.nix` so opencode uses the Nix build anyway.
  nix-ld also fixes Zed's other self-downloaded LSPs (ruff, basedpyright,
  bash-language-server, …). Needs a relogin for `NIX_LD*`.
  - Mechanics: `programs.nix-ld.enable` sets `environment.ldso =
    <nix-ld>/libexec/nix-ld` (so `/lib64/ld-linux-x86-64.so.2` → nix-ld, not
    stub-ld) plus `environment.sessionVariables.NIX_LD` /
    `NIX_LD_LIBRARY_PATH` (session-scoped, hence relogin). Verify with
    `readlink -f /lib64/ld-linux-x86-64.so.2` (stub-ld ⇒ not active) and
    `grep NIX_LD /etc/set-environment`. The registry-downloaded opencode was
    confirmed to run under nix-ld (`--version` → its upstream version), so
    nix-ld alone is a sufficient fallback; the `custom` override is
    belt-and-suspenders (deterministic, no ~185 MB download).
  - `agent_servers` is keyed by agent id with a tagged `type`
    (`custom` ⇒ `LocalCustomAgent`, `registry` ⇒ download; see Zed's
    `crates/project/src/agent_server_store.rs`), so shadowing the registry id
    `opencode` with `type = "custom"` + `command`/`args` makes Zed run the Nix
    binary and never touch the registry copy. The HM zed module merges generated
    settings into the *writable* `~/.config/zed/settings.json` via
    `zedSettingsActivation` (pyjson5 + jaq deep-merge, static scalars win; keys
    only in the live file survive — the merge cannot delete). **Quit Zed before
    `switch`** so it can't rewrite settings.json on exit and clobber the merge.
    Verify: `grep -A5 agent_servers ~/.config/zed/settings.json` must show
    `opencode` as `"type": "custom"`, and the HM store file (`…-zed-user-settings`
    in the active generation) must contain `agent_servers` at all.

### Open regressions vs legacy (need a decision — do not silently ignore)
Runtime:
- `networking.networkmanager.enable` is NOT set anywhere (legacy `true`) → the
  Plasma network applet and `nmcli` are non-functional; only appears in
  `extraGroups`. Note: this is intentional for the router `skullsaint`; if/when
  re-enabled, do it per client host (e.g. acer-aspire), not in the `core` base
  feature.
- `sunny` login shell is bash; legacy set `users.users.sunny.shell = pkgs.zsh`.
  `home.shell.enableZshIntegration`/`SHELL` do NOT change the login shell.
- Dropped from legacy: `services.printing`,
  `programs.fuse.userAllowOther`, `programs.bat`,
  `programs.firefox` (makes the catppuccin firefox toggle inert),
  `programs.partition-manager`, `networking.nameservers`,
  firewall TCP `9300` (Quick Share/Phone Link), GRUB
  `boot.loader.grub.theme` (lobo), and many
  `environment.systemPackages`/user packages (btop, gdu, haruna, resvg,
  libreoffice-qt-fresh, gimp2-with-plugins, qtscrcpy, testdisk-qt, obs-studio,
  kdenlive, veracrypt, brave, notion-app, bitwarden-desktop, conda, superfile…).

Loopholes:
- `sddm-sword` is effectively inert: qylock `sddm.enable = false` +
  `quickshell.enable = false`, so `theme = "sword"` never applies (catppuccin
  owns SDDM). It installs qylock for no visible effect.
- `hosts/acer-aspire/resources/garfield.jpeg` is actually a PNG.
- Docs drift: the `bluetooth` bullet claims `kx` BT-audio codecs, but the module
  only sets `Enable = "Source,Sink,Media,Socket"`.
- `baseServices` forces GRUB (`services/boot.nix`) onto every host, including
  `skullsaint`; revisit if a host ever needs a different bootloader.

### Testing technique (there is no test suite)
Isolate one registered module without building a host:
`(import ./features/nixos/<f>.nix { }).flake.modules.nixos.<name>` is the real
module function (services: `(import ./services/<s>.nix { }).flake.services.<name>`)
— feed it to `lib.nixosSystem`. To check `assertions`, map
`config.assertions` to `.assertion` and look for `false`. `nix flake check` does
not force every option, so dump specific ones with
`nix eval --impure --json --expr '...'` (remember untracked files need `git add`).

## Knowledge base
- awesome-nix (curated list of Nix resources/tools):
  https://github.com/nix-community/awesome-nix
- nix.dev — official tutorials & best practices: https://nix.dev
- Packages / options search: https://search.nixos.org
- NixOS Wiki: https://wiki.nixos.org
- home-manager options reference:
  https://nix-community.github.io/home-manager/options.xhtml
- NixOS & Flakes Book (practical guide): https://nixos-and-flakes.thiscute.world
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
- Some packages need: `NIXPKGS_ALLOW_INSECURE=1` (e.g. `NIXPKGS_ALLOW_INSECURE=1 sudo -E nixos-rebuild switch --flake . --impure`)
- Stage new `.nix` files (`git add`, even `-N`) and `nix flake check` before
  committing: the flake ignores untracked files.

## Architecture
- `flake.nix` imports `core/ features/ services/ users/ hosts/` via `import-tree`;
  every file is auto-imported EXCEPT names starting with `_` (`_pkg.nix`,
  `_hardware.nix`) — import those explicitly (both `users/*/<name>.nix` import
  `./_pkg.nix`).
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
  (`zsh fastfetch neovim oh-my-posh zed kde-all git catppuccin obsidian opencode`); hosts
  opt into nixos features via `features = [...]` and system services via
  `services = [...]`.
- Feature/service files are themselves flake-parts modules: a top-level fn only
  receives flake-parts args (`config`/`inputs`/`lib`), NOT `pkgs`. Take
  `pkgs`/`inputs` as INNER args of the registered module
  (`flake.modules.homeManager.x = { pkgs, inputs, ... }:` or
  `flake.services.x = { pkgs, ... }:`), as in `zsh.nix`/`boot.nix`/`services/openssh.nix`.
- Two package sets, both module args everywhere (NixOS `specialArgs` + HM
  `extraSpecialArgs` in `core/hosts.nix`): `pkgs` = nixos-unstable,
  `stable-pkgs` = nixos-26.05, both `allowUnfree`.

- Custom packages live under `pkgs/<name>/default.nix` and are exposed via
  `overlays/default.nix` (applied to both `pkgs` and `stable-pkgs` in
  `core/hosts.nix`), so consumers can use `pkgs.<name>`. AppImages use
  `appimageTools.wrapType2` for proper desktop entry/icon integration.

## Hosts
- Host key is `hosts.<attr>`, NOT the directory name: `hosts/skullsaints/default.nix`
  defines `hosts.skullsaint` → `.#skullsaint`.
- `acer-aspire` (x86_64-linux): features sddm-sword (qylock, inert — see under
  Catppuccin below), kde, kdeconnect, catppuccin, openlogi; services audio,
  bluetooth, nvidia (Intel+NVIDIA prime sync; bus IDs are hardware-specific),
  sddm, virt-manager, openssh. Evaluates. Its `extra` overrides
  `catppuccin.sddm.background` with
  the host-local `hosts/acer-aspire/resources/garfield.jpeg`.
- `skullsaint` (x86_64-linux, users sunny+route): **router machine** — will do
  WAN↔LAN routing, NAT, DHCP/DNS, so it must NOT run NetworkManager (client-side
  tool that fights static router interfaces). Ethernet takes over; no Plasma/KDE.
  `_hardware.nix` is committed, so it evaluates. Regenerate it on the machine
  with `nixos-generate-config --show-hardware-config > hosts/skullsaints/_hardware.nix`.
  No host features; services openssh (plus `boot` via `baseServices`).

## Current features / users
- homeManager: `zsh` (shell + SHELL env), `fastfetch` (logo commented out),
  `neovim` (nvf via `inputs.nvf.homeManagerModules.default` + `programs.neovim`),
  `oh-my-posh` (custom prompt; glyphs via JSON `\uXXXX` trick, schema URL kept on
  `main`), `zed` (zed-editor + marksman/harper/nixd LSPs, nixfmt), `git`
  (`programs.git` — lfs, SSH signing via `~/.ssh/github.pub` + `signByDefault`,
  user/init settings, `git-filter-repo` in `home.packages`; also `programs.lazygit`
  + zsh integration, merged in from the old `lazygit` feature), `catppuccin` (imports
  `inputs.catppuccin.homeModules.catppuccin`; global mocha/teal + brave/firefox/
  obs/qt5ct/lazygit/opencode/zsh-syntax-highlighting toggles; neovim theming lives in
  `neovim.nix` via nvf `vim.theme = "catppuccin"`), `obsidian`
  (`programs.obsidian`; vault `notes` → `Documents/Obsidian`; community plugins
  `dataview`/`obsidian-git`/`obsidian-importer`/`vim-yank-highlight` + `catppuccin`
  theme, all from `pkgs.obsidianPlugins`/`pkgs.obsidianThemes` supplied by a
  **feature-local** `import inputs.nixpkgs { overlays = [ inputs.obsidian-extensions.overlays.default ]; }`
  — no global overlay), `opencode` (`programs.opencode` minimal: enable +
  `extraPackages` ripgrep/fd/fzf; NO `model` set so you pick one via `/models`;
  TUI theme owned by the `catppuccin` feature's `catppuccin.opencode` toggle,
  which sets `programs.opencode.tui.theme`), `profile-picture` (option
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
  Solaar StatusNotifier icon in the popup, not the bar — safe when solaar is off,
  it's just an unmatched id), `kde-workspace` (theming pkgs: catppuccin-kde/gtk, papirus,
  graphite-cursors; look&feel, keyboard layout in/eng via
  `programs.plasma.input.keyboard`), `kde-kwin` (effects/titlebar/shortcuts +
  `inputs.kwin-effects-better-blur-dx` pkg), `kde-power` (powerdevil),
  `kde-session` (restore/kscreenlocker/mouse), `kde-krunner`, `kde-fonts`
  (fonts.fontconfig + nerd/noto fonts),   `kde-apps` (ALL KDE user packages in
  `home.packages`), `kde-konsole` (programs.konsole). `kde-all` imports
  the whole family in one go, **plus `nixdatifier`** (top-level HM feature, see
  its own bullet). No Plasma/KDE packages at the system level — it's
  all HM (plasma-manager generates `plasma-workspace/kwin` config from HM).
- nixos features: `core` (base feature: `nix.settings.experimental-features`,
  `auto-optimise-store`, `nix.settings.trusted-users` = root + `core.dotfileUser`,
  and `programs.nh` with `flake` derived from that user's home — no hardcoded
  path/username; every host must set `core.dotfileUser` in its `extra`,
  otherwise eval fails), `sddm-sword` (qylock module via
  `inputs.qylock.nixosModules.default`; `sddm.enable = false` so theming is owned
  by `catppuccin`; acer-aspire only), `kde` (minimal:
  `services.desktopManager.plasma6.enable` + Discover excluded; acer-aspire only),
  `kdeconnect` (avahi + firewall 1714-1764; acer-aspire only), `catppuccin`
  (imports `inputs.catppuccin.nixosModules.catppuccin`; global mocha/teal,
  cursors + SDDM theme; acer-aspire only), `solaar` (native `programs.solaar`:
  `enable` + `userService.enable`/`window = "hide"`; module **kept but not
  enabled on any host** — Solaar and OpenLogi fight over HID++ receiver access,
  and acer-aspire runs `openlogi` instead), `openlogi` (local-first Logitech
  HID++ manager; **no longer a flake input** — the upstream module is inlined
  against `pkgs.openlogi`, the cached cache.nixos.org build, so there is no Rust
  compile; installs the package (CLI + `openlogi-gui` + `.desktop`),
  `70-openlogi.rules` via `services.udev.packages`, and
  `systemd.user.services.openlogi-agent` on `graphical-session.target`;
  acer-aspire only), `internationalization` (base feature:
  `time.timeZone = "Asia/Kolkata"`, `i18n.defaultLocale = "en_IN"` + `LC_*`
  extraSettings; keyboard layout lives in the HM `kde-workspace` feature).
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
  kvm users opt in via `extraGroups`; acer-aspire).
- users: `sunny` (both hosts; extraGroups wheel/networkmanager/libvirtd/kvm),
  `route` (skullsaint only); packages: sunny `pkgs.lshw`, route `stable-pkgs.wget`,
  acer-aspire `pkgs.lshw`, skullsaints `stable-pkgs.lshw`.

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

## NixOS best practices (this repo)
- Compose, don't override: `allowUnfree`, `useGlobalPkgs`/`useUserPackages`,
  `baseFeatures`/`baseServices` are global — don't re-set per host/user.
- Keep features reusable: no hardcoded usernames; grant access via a user's
  `extraGroups` or a host's `extra`. NixOS auto-derives `users.groups.*.members`
  from `extraGroups`.
- Stability-sensitive packages → `stable-pkgs.X`; newest → `pkgs.X`.
- Never hand-edit `_hardware.nix`; regenerate with `nixos-generate-config`.
- Pull external modules (e.g. nvf) via the flake's `homeManagerModules.default` /
  `nixosModules.default` in the feature file.
- Keep per-user/per-host package lists in `_pkg.nix` files, not inline modules.
- Run `nix flake check` after changes (validates both hosts).

## Regression audit (nix-dendrite migration)
Findings from back-testing the flake against legacy `system/`+`user/` and from
isolated module evals. Learn these before adding features.

### Fixed in-tree
- `features/nixos/core.nix`: `trusted-users` hardcoded `"sunny"` → now `[ cfg ]`
  (`cfg = core.dotfileUser`). Regression test: eval the module with
  `dotfileUser = "route"` and confirm `nix.settings.trusted-users` and
  `programs.nh.flake` agree (`["root","route"]` + `/home/route/.dotfile`).
- `features/homeManager/kde/kwin.nix`: `pkgs.system` → `pkgs.stdenv.hostPlatform.system`
  (old form warns `'system' has been renamed…` and is slated for removal).
- `features/homeManager/zed.nix`: nixd `expr`s hardcoded `/home/sunny` +
  `nixosConfigurations.acer-aspire` and pointed at a nonexistent
  `homeConfigurations` output. Now uses `${config.home.homeDirectory}` +
  `${osConfig.networking.hostName}` (`osConfig` is injected by HM when it runs as
  a NixOS module — see `common.nix`). There is no `home_manager.expr` because the
  flake exports no `homeConfigurations`; add that output if you ever want it.

### Open regressions vs legacy (need a decision — do not silently ignore)
Runtime:
- `networking.networkmanager.enable` is NOT set anywhere (legacy `true`) → the
  Plasma network applet and `nmcli` are non-functional; only appears in
  `extraGroups`. Note: this is intentional for the router `skullsaint`; if/when
  re-enabled, do it per client host (e.g. acer-aspire), not in the `core` base
  feature.
- `sunny` login shell is bash; legacy set `users.users.sunny.shell = pkgs.zsh`.
  `home.shell.enableZshIntegration`/`SHELL` do NOT change the login shell.
- `features/homeManager/zsh.nix` runs `eval "$(devenv hook zsh)"` but `devenv`
  (and legacy `programs.direnv`/`nix-direnv`) is not installed → error on every
  shell start.
- Dropped from legacy: `services.printing`, `programs.nix-ld`,
  `programs.fuse.userAllowOther`, `programs.direnv`, `programs.bat`,
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
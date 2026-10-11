# AGENTS.md

NixOS flake (flake-parts + import-tree). Branch `nix-dendrite` re-architects the
old `system/`+`user/` layout into `core/ features/ users/ hosts/`. The legacy
`user/` and `system/` dirs are stale leftovers — ignore them, do not edit.

## Commands
- Evaluate everything: `nix flake check` (no test suite; this is it)
- Build a host: `nixos-rebuild build --flake .#<host>` (or `.#<host>` on the machine)
- Apply: `sudo nixos-rebuild switch --flake .#<host>`
- Update inputs: `nix flake update`
- Some packages need: `NIXPKGS_ALLOW_INSECURE=1` (e.g. `NIXPKGS_ALLOW_INSECURE=1 sudo -E nixos-rebuild switch --flake . --impure`)
- Stage new `.nix` files (`git add`, even `-N`) and `nix flake check` before
  committing: the flake ignores untracked files.

## Architecture
- `flake.nix` imports `core/ features/ users/ hosts/` via `import-tree`; every
  file is auto-imported EXCEPT names starting with `_` (`_pkg.nix`,
  `_hardware.nix`) — import those explicitly (both `users/*/<name>.nix` import
  `./_pkg.nix`).
- Feature/user files register `flake.modules.nixos.<name>` and
  `flake.modules.homeManager.<name>`.
- `core/hosts.nix` registry `hosts.<name>` → `nixosConfigurations.<name>`,
  composing: `users` (nixos + homeManager modules), `features` (nixos modules),
  `baseFeatures = [ "boot" "internationalization" "core" ]` (every host), `extra` (raw NixOS modules: hardware,
  `_pkg.nix`, stateVersion).
- Users opt into homeManager features via `imports` in their `<name>.nix`
  (`zsh fastfetch neovim oh-my-posh zed kde-all git lazygit catppuccin obsidian opencode`); hosts
  opt into nixos features via `features = [...]`.
- Feature files are themselves flake-parts modules: a top-level fn only receives
  flake-parts args (`config`/`inputs`/`lib`), NOT `pkgs`. Take `pkgs`/`inputs`
  as INNER args of the registered module (`flake.modules.homeManager.x = { pkgs, inputs, ... }:`),
  as in `zsh.nix`/`boot.nix`.
- Two package sets, both module args everywhere (NixOS `specialArgs` + HM
  `extraSpecialArgs` in `core/hosts.nix`): `pkgs` = nixos-unstable,
  `stable-pkgs` = nixos-26.05, both `allowUnfree`.

## Hosts
- Host key is `hosts.<attr>`, NOT the directory name: `hosts/skullsaints/default.nix`
  defines `hosts.skullsaint` → `.#skullsaint`.
- `acer-aspire` (x86_64-linux): features virt-manager, nvidia (Intel+NVIDIA prime
  sync; bus IDs are hardware-specific), sddm, sddm-sword, kde, kdeconnect,
  openssh, catppuccin, audio, bluetooth, openlogi. Evaluates. Its `extra` overrides
  `catppuccin.sddm.background` with
  the host-local `hosts/acer-aspire/resources/garfield.jpeg`.
- `skullsaint` (x86_64-linux, users sunny+route): `_hardware.nix`
  is committed, so it evaluates. Regenerate it on the machine with
  `nixos-generate-config --show-hardware-config > hosts/skullsaints/_hardware.nix`.

## Current features / users
- homeManager: `zsh` (shell + SHELL env), `fastfetch` (logo commented out),
  `neovim` (nvf via `inputs.nvf.homeManagerModules.default` + `programs.neovim`),
  `oh-my-posh` (custom prompt; glyphs via JSON `\uXXXX` trick, schema URL kept on
  `main`), `zed` (zed-editor + marksman/harper/nixd LSPs, nixfmt), `git`
  (`programs.git` — lfs, SSH signing via `~/.ssh/github.pub` + `signByDefault`,
  user/init settings, `git-filter-repo` in `home.packages`), `lazygit`
  (`programs.lazygit` + zsh integration), `catppuccin` (imports
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
  which sets `programs.opencode.tui.theme`).
- homeManager `kde/` family (dir features/homeManager/kde): `kde` (core — imports
  `inputs.plasma-manager.homeModules.plasma-manager`, plasma.enable), `kde-desktop`
  (panels/systray; `systemTray.items.hidden = [ "indicator-solaar" ]` keeps the
  Solaar StatusNotifier icon in the popup, not the bar — safe when solaar is off,
  it's just an unmatched id), `kde-workspace` (theming pkgs: catppuccin-kde/gtk, papirus,
  graphite-cursors; look&feel, keyboard layout in/eng via
  `programs.plasma.input.keyboard`), `kde-kwin` (effects/titlebar/shortcuts +
  `inputs.kwin-effects-better-blur-dx` pkg), `kde-power` (powerdevil),
  `kde-session` (restore/kscreenlocker/mouse), `kde-krunner`, `kde-fonts`
  (fonts.fontconfig + nerd/noto fonts), `kde-apps` (ALL KDE user packages in
  `home.packages`), `kde-konsole` (programs.konsole). `kde-all` imports the whole
  family in one go. No Plasma/KDE packages at the system level — it's all HM
  (plasma-manager generates `plasma-workspace/kwin` config from HM).
- nixos: `core` (base feature: `nix.settings.experimental-features`,
  `auto-optimise-store`, `nix.settings.trusted-users` = root + `core.dotfileUser`,
  and `programs.nh` with `flake` derived from that user's home — no hardcoded
  path/username; every host must set `core.dotfileUser` in its `extra`,
  otherwise eval fails), `boot`, `virt-manager` (libvirtd/kvm users opt in via `extraGroups`),
  `nvidia`, `sddm` (base SDDM/Wayland/KWin), `sddm-sword` (qylock module via
  `inputs.qylock.nixosModules.default`; `sddm.enable = false` so theming is owned
  by `catppuccin`; acer-aspire only), `kde` (minimal:
  `services.desktopManager.plasma6.enable` + Discover excluded; acer-aspire only),
  `kdeconnect` (avahi + firewall 1714-1764; acer-aspire only), `catppuccin`
  (imports `inputs.catppuccin.nixosModules.catppuccin`; global mocha/teal,
  cursors + SDDM theme; acer-aspire only), `audio` (PipeWire: alsa 32-bit/pulse/
  jack + `security.rtkit`; `qpwgraph` in `environment.systemPackages`;
  acer-aspire only), `bluetooth` (bluez via `hardware.bluetooth`:
  Experimental/FastConnectable/AutoEnable + `Enable = "Source,Sink,Media,Socket"`
  `kx` BT-audio codecs; acer-aspire only), `solaar` (native `programs.solaar`:
  `enable` + `userService.enable`/`window = "hide"`; module **kept but not
  enabled on any host** — Solaar and OpenLogi fight over HID++ receiver access,
  and acer-aspire runs `openlogi` instead), `openlogi` (imports
  `inputs.openlogi.nixosModules.default` — local-first Rust Logitech HID++
  manager; `programs.openlogi.enable` + `launchAtLogin`; installs the package,
  `70-openlogi.rules` via `services.udev.packages`, and
  `systemd.user.services.openlogi-agent` on `graphical-session.target`;
  acer-aspire only), `internationalization` (base feature:
  `time.timeZone = "Asia/Kolkata"`, `i18n.defaultLocale = "en_IN"` + `LC_*`
  extraSettings; keyboard layout lives in the HM `kde-workspace` feature).
- users: `sunny` (both hosts; extraGroups wheel/networkmanager/libvirtd/kvm),
  `route` (skullsaint only); packages: sunny `pkgs.lshw`, route `stable-pkgs.wget`,
  acer-aspire `pkgs.lshw`, skullsaints `stable-pkgs.lshw`.

## Gotchas
- Untracked `.nix` files are NOT part of the flake source: run `git add` (even
  `-N`) before `nix flake check`/eval can see them.
- `home.username` / `home.homeDirectory` are derived from `users.users.<name>.home`;
  set `home` on the account, don't set them inside home-manager (same-priority
  conflict with HM's common.nix).
- `nix flake check` prints `warning: unknown flake output 'modules'` — harmless
  (flake-parts `modules` flakeModule); silence via `touchup` if desired.
- Do NOT change `system.stateVersion` / `home.stateVersion` (`"25.11"`).
- README.md has been rewritten for the flake layout (stale notes about the old
  single-file `configuration.nix` / standalone home-manager are gone). Trust
  flake/core. `user/` + `system/` dirs are stale leftovers grandfathered in.
- `.gitignore`'s `system/hardware-configuration.nix` is stale; hardware lives at
  `hosts/<host>/_hardware.nix` and is committed.

## NixOS best practices (this repo)
- Compose, don't override: `allowUnfree`, `useGlobalPkgs`/`useUserPackages`,
  `baseFeatures` are global — don't re-set per host/user.
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
  `extraGroups`.
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
  `boot.loader.grub.theme` (lobo), `~/.face`/`~/.face.icon`, and many
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
- `baseFeatures` forces GRUB (`boot.nix`) onto every host, including
  `skullsaint`; revisit if a host ever needs a different bootloader.

### Testing technique (there is no test suite)
Isolate one registered module without building a host:
`(import ./features/nixos/<f>.nix { }).flake.modules.nixos.<name>` is the real
module function — feed it to `lib.nixosSystem`. To check `assertions`, map
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
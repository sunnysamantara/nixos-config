# NixOS security

Hardening, secrets management, and sandboxing for NixOS. Declarative configuration and immutable store paths enable reproducible and auditable security postures.

## Hardening baseline (opt-in -- there is no hardened profile)

**NixOS removed `profiles/hardened.nix` in 26.05**, together with the `linux_hardened` kernel (`linuxPackages_hardened`). Upstream reasons: no coherent baseline, hidden breakage, unclear benefit ([26.05 release notes](https://nixos.org/manual/nixos/stable/#sec-release-26.05-incompatibilities-profiles-hardened-removed)).

The file still exists as a stub -- and that is the trap:

```nix
# WRONG on 26.05+: evaluates without error, applies nothing.
imports = [ "${modulesPath}/profiles/hardened.nix" ];
```

The stub only errors if `profiles.hardened` is *set*; importing it alone silently gives **zero** hardening and a false sense of safety. `boot.kernelPackages = pkgs.linuxPackages_hardened` no longer evaluates at all. Choose controls explicitly instead:

```nix
{
  # Kernel information-leak and interface hardening
  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;       # hide kernel pointers from unprivileged reads
    "kernel.dmesg_restrict" = 1;      # require CAP_SYSLOG for dmesg
    "kernel.sysrq" = 0;               # disable magic SysRq keys
    "kernel.perf_event_paranoid" = 2; # 3 blocks perf entirely (breaks profiling)
  };

  security.protectKernelImage = true; # keep the kernel image from being overwritten (kexec)
  security.lockKernelModules = true;  # no module load/unload after boot
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true; # kill processes not confined by any profile
  };
  security.sudo.wheelNeedsPassword = true;
}
```

Tradeoffs, all deliberate: `lockKernelModules` breaks hardware needing late module loads (some Wi-Fi/GPU firmware paths); `dmesg_restrict` hides diagnostics from unprivileged debugging; AppArmor needs a reboot on first activation, and profile paths must reference `/nix/store` locations, so absolute-path rules copied from other distros do not apply. Audit with `sysctl --system`, `aa-status`, and `systemd-analyze security <unit>` (score 0.0 = safest, 10.0 = worst). Further menu of options: [NixOS Hardening wiki](https://wiki.nixos.org/wiki/NixOS_Hardening).

### security.allowUserNamespaces

Defaults to `true` -- keep it. Turning it off (the old hardened profile did) trips a nixpkgs assertion against `nix.settings.sandbox = true` (`sandbox -> allowUserNamespaces`), so the pair fails evaluation; the only way to satisfy that assertion is `sandbox = false` (see Nix build sandbox below) -- a strictly worse trade. User namespaces are required by rootless Podman, Bubblewrap, Flatpak, and by Nix's own Linux sandbox, which is exactly what the assertion protects.

## Firewall

The NixOS firewall is default-deny: only `allowedTCPPorts`/`allowedUDPPorts` and ports opened by services are reachable.

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 22 80 443 ];
  allowedUDPPorts = [ ];
  allowPing = true;
  logRefusedConnections = true; # log drops while auditing, quiet later
};
```

- Scope instead of blanket-opening where possible: `networking.firewall.interfaces."eth0".allowedTCPPorts = [ 22 ];` or `allowedTCPPortRanges`.
- Reverse path filtering: `networking.firewall.checkReversePath` defaults to `"loose"`. Multi-WAN routers, VPNs, tunnels, and asymmetric routing can drop legitimate traffic -- set it to `false` there and compensate with your own routing checks.
- The firewall does **not** rate-limit: pair exposed SSH with `services.fail2ban` (below) or an upstream filter.
- firewalld is available as an alternative (added in 25.11): `services.firewalld.enable = true;`

## Exposed services: SSH first

SSH on 0.0.0.0 is the highest-value surface on any host. Beyond the basics:

```nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
    X11Forwarding = false;
    MaxAuthTries = 3;
    AllowUsers = [ "alice" ]; # optional, but sharp
  };
};
networking.firewall.allowedTCPPorts = [ 22 ];

services.fail2ban = {
  enable = true; # sshd jail enabled by default
  jails.DEFAULT.settings = {
    maxretry = 3;
    bantime = "1h";
  };
};
```

Audit listening sockets with `ss -tulpn` against `networking.firewall` -- anything listening on a routable interface is exposed, regardless of what you intended to open.

## User accounts and passwords

Nix store paths are world-readable and git history is permanent. Both of these leak credentials:

- `users.users.<name>.password` / `.initialPassword` -- **plaintext** credential in the store. Never.
- `users.users.<name>.hashedPassword` -- the hash lands in `/nix/store` *and* git: an offline cracking target forever. The same hash for two accounts means the same password on both.

Prefer a hash file outside the store, provisioned once (root-only):

```bash
# one-time, outside the flake tree; 600 root:root
mkdir -p /var/lib/nixos-secrets && chmod 700 /var/lib/nixos-secrets
openssl passwd -6 > /var/lib/nixos-secrets/alice.hash   # prompts for the password
```

```nix
users.users.alice = {
  isNormalUser = true;
  hashedPasswordFile = "/var/lib/nixos-secrets/alice.hash";
};
```

Activation semantics (from `update-users-groups.pl`):

| `users.mutableUsers` | Declarative hash applied | Interactive `passwd` |
| :--- | :--- | :--- |
| `true` (default) | only when the account is **created** | persists across switches |
| `false` | on **every** activation | reverted on every switch |

- `mutableUsers = false` + `initialHashedPassword`/`hashedPasswordFile` gives a fully declarative account whose password only changes via rebuild.
- Provision `hashedPasswordFile` **before** the first switch: a missing file produces an activation warning, and a *new* account is created locked (`!`).
- Leak response: **rotate the password**. Replacing the file does not un-leak an exposed hash; if the hash was committed and pushed, purge history (e.g. `git filter-repo`) or assume it is public.
- Pair with `security.sudo.wheelNeedsPassword = true` (if `false`, wheel is root with no barrier) and SSH `PasswordAuthentication = false`.

## Nix daemon trust: trusted-users

```nix
nix.settings.trusted-users = [ "root" "alice" ]; # never "*"
```

Trusted users may supply their own `substituters` and `trusted-public-keys`. Paths fetched from a cache *they* control are accepted without signature checks against the default keys, enter the shared store, and are then reused by other users' builds of the same derivation -- on a multi-user machine, treat `trusted-users` as an admin-only list (root is the only default member).

Related rules:

- Keep `nix.settings.sandbox = true` (it requires `security.allowUserNamespaces`, above).
- Never `nix.settings.require-sigs = false`.
- Avoid `nix.settings.extra-sandbox-paths`: host paths leak into supposedly hermetic builds.

## Secrets management

Never store secrets in the Nix store -- store paths are world-readable.

### sops-nix

Encrypts secrets with age keys. Decrypts at activation time.

```nix
# flake.nix inputs
sops-nix.url = "github:Mic92/sops-nix";
sops-nix.inputs.nixpkgs.follows = "nixpkgs";

# configuration.nix
sops = {
  defaultSopsFile = ./secrets/secrets.yaml;
  age.keyFile = "/var/lib/sops-nix/key.txt";

  secrets.db-password = {
    owner = "postgres";
    group = "postgres";
    mode = "0400";
  };
};
```

Secrets decrypt to `/run/secrets/<name>` (tmpfs -- gone on reboot, never in the store) by default. Generate the age key with `age-keygen -o /var/lib/sops-nix/key.txt` (age writes it 0600; verify with `stat -c %a`).

Encrypt:

```bash
sops --age $(age-keygen -y /var/lib/sops-nix/key.txt) secrets/secrets.yaml
```

Key hygiene, both tools:

- **Back up the key offline.** Losing it means the encrypted files are permanently unreadable; anyone who obtains it can decrypt every secret they are a recipient of. Keep it out of the store, out of git, and out of synced dotfile dirs.
- Never leave a plaintext sibling next to `defaultSopsFile` -- one `git add .` away from a leak.
- Set `owner`/`group`/`mode` for every secret so the consuming service can read it and nothing else can (`0400` is the usual floor; defaults are root-only, so `DynamicUser`/non-root services fail until you set the owner).
- At Home Manager level the age key sits in the user's home: any process running as that user can read it. Use `mode = "0400"` and account for home-dir backups/sync.

### agenix

Encrypts with age using SSH host/user keys. Lighter weight than sops-nix.

```nix
age.secrets.db-password = {
  file = ./secrets/db-password.age;
  owner = "postgres";
  group = "postgres";
  mode = "0400";
};
```

Encrypt:

```bash
agenix -e secrets/db-password.age
```

### Comparison

| Feature | sops-nix | agenix |
| :--- | :--- | :--- |
| Key type | age keys (separate from SSH) | age via SSH keys |
| Secret format | YAML, JSON, env, binary | Single file per secret |
| Multi-key encryption | Yes (multiple recipients) | Yes (via `secrets.nix`) |
| Editor integration | `sops` CLI opens in `$EDITOR` | `agenix -e` opens in `$EDITOR` |
| Complexity | More features, more config | Minimal, fewer moving parts |

Both decrypt secrets to `/run/secrets/` at activation. Choose based on existing key infrastructure.

### Secrets in runtime state

- Never pass secrets as command-line arguments -- visible in `ps` and often in the journal. Use file paths or `EnvironmentFile=`.
- Environment variables leak: `/proc/<pid>/environ`, `systemctl show`, exported shells, crash reports. Prefer file-based credentials.
- Watch what services log: config dumps and error messages in journald persist and may be world-readable.

## Systemd service sandboxing

Harden individual services with systemd security options:

```nix
systemd.services.my-service = {
  serviceConfig = {
    DynamicUser = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    NoNewPrivileges = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
    RestrictNamespaces = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    CapabilityBoundingSet = [ "" ];       # drop all capabilities
    SystemCallFilter = [ "@system-service" ];
    SystemCallArchitectures = "native";
    ReadWritePaths = [ "/var/lib/my-service" ];
  };
};
```

The example will break some services as written -- know the traps:

| Setting | Commonly breaks | Fix |
| :--- | :--- | :--- |
| `MemoryDenyWriteExecute` | JVM, Go, .NET, anything JIT | drop it for that unit |
| `CapabilityBoundingSet = [ "" ]` | binding ports < 1024 | add `AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ]` |
| `ProtectHome = true` | services reading `/home` | softer: `"read-only"` or `"tmpfs"` |
| `DynamicUser = true` | state written anywhere ad hoc | declare `StateDirectory=`/`CacheDirectory=` (created with the right owner) |
| `SystemCallFilter = [ "@system-service" ]` | occasionally databases/ffmpeg | extend the allowlist only after testing |

Prefer `StateDirectory=`/`RuntimeDirectory=` over hand-listed `ReadWritePaths`: the directories are created, owned, cleaned up correctly, and survive `ProtectSystem = "strict"` by design.

Use `systemd-analyze security my-service.service` to audit exposure scores (0.0 safest -- 10.0 worst) and iterate.

## Disk encryption and secure boot

### LUKS

```nix
boot.initrd.luks.devices.cryptroot = {
  device = "/dev/disk/by-uuid/...";
  preLVM = true;
};
```

### Secure boot

Plain systemd-boot is **not** Secure Boot:

```nix
# UEFI firmware Secure Boot enforcement still needs signing (Lanzaboote below).
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
```

Options that actually sign/verify what boots:

- Lanzaboote (community project): `boot.lanzaboote = { enable = true; pkiBundle = "/etc/secureboot"; };`
- Limine (since 25.11): `boot.loader.limine.secureBoot.enable = true;` -- signs the bootloader; kernels are hashed at rebuild so only NixOS-built kernels boot.

**`pkiBundle` must be an absolute path outside the flake** (`"/etc/secureboot"`). A relative path (`./secureboot`) is copied into the **world-readable Nix store** -- your Secure Boot signing keys would then be readable by every local user. Same rule for any key material: never reference it as a Nix path literal.

## Impermanence pattern

Run the root filesystem on tmpfs so state resets on reboot. Persist only declared paths:

```nix
environment.persistence."/persist" = {
  directories = [
    "/var/log"
    "/var/lib/nixos"           # uid/gid map
    "/var/lib/systemd"
    "/etc/NetworkManager/system-connections"
    "/var/lib/AccountsService" # user icons/avatars
    "/etc/ssh"                 # host keys: regenerated keys break every known_hosts client
  ];
  files = [
    "/etc/machine-id"
  ];
};
```

No undeclared state accumulates between reboots -- which also removes persistence mechanisms malware relies on and makes audits tractable. Requires the [impermanence](https://github.com/nix-community/impermanence) module.

## Nix build sandbox

Nix builds run in a sandbox by default on Linux (`sandbox = true` in `nix.conf`). The sandbox:
- Restricts network access during builds
- Provides a minimal filesystem (only declared inputs)
- Prevents builds from reading host state

Fixed-output derivations (fetchers) are allowed network access because their output is verified by hash.

- Never disable `nix.settings.sandbox` -- it is the strongest build isolation (network off, minimal filesystem, no host state). Trap: the *only* way to satisfy `security.allowUserNamespaces = false` (above) is `sandbox = false`, i.e. that old hardened-profile combination silently meant **no build sandbox at all**.
- `extra-sandbox-paths` punches host paths into every build -- treat each entry as a reproducibility and integrity hole.

macOS sandboxing is more limited but enabled by default on nix-darwin.

## Supply chain

- **Evaluating a flake executes the Nix code of every input, before any sandbox runs.** A flake input is arbitrary code at eval time; reviewing only the *build* of your own config is not enough. Minimize inputs, pin third-party ones to an exact `rev` (not a floating branch), and prefer inputs whose nixpkgs you align via `follows`.
- Review every `nix flake update` diff -- in particular **owner/repo changes** in the lock (a renamed or transferred repository is a takeover vector), unexpected new inputs, and `narHash` movement you did not trigger.
- Adding a substituter (globally or via a flake's `nixConfig.extra-substituters`) is trusting that cache's `trusted-public-keys`: it can serve the exact bytes your builds install. Nix prompts unprivileged users before honouring flake-declared substituters -- treat the prompt as a red flag and verify keys first.
- Pin fetcher sources with `rev` + SRI hash (`sha256-...=`). For fixed-output derivations the hash is the *only* integrity check (no signatures): generate hashes yourself (`nix hash`, prefetch) rather than copying them from an untrusted snippet.
- Prefer upgrading over insecure packages: `knownVulnerabilities` / `NIXPKGS_ALLOW_INSECURE` should be scoped to the one package that needs it, with a reason, never a blanket habit.
- Consider `nix store verify --all` to check store path signatures.
- Reproducible builds: the same inputs should produce bit-identical outputs. nixpkgs CI tests this for core packages.

## Key references

- [NixOS Hardening wiki](https://wiki.nixos.org/wiki/NixOS_Hardening)
- [26.05 release notes: hardened profile removal](https://nixos.org/manual/nixos/stable/#sec-release-26.05-incompatibilities-profiles-hardened-removed)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [agenix](https://github.com/ryantm/agenix)
- [impermanence](https://github.com/nix-community/impermanence)
- [Lanzaboote](https://github.com/nix-community/lanzaboote)
- [NixOS wiki: comparison of secret managing schemes](https://wiki.nixos.org/wiki/Comparison_of_secret_managing_schemes)
- [NixOS wiki: systemd sandboxing](https://wiki.nixos.org/wiki/Sandboxing_programs)

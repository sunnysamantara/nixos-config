# nixos-config

https://www.youtube.com/@matthiasbenaets

https://www.youtube.com/@librephoenix

https://www.youtube.com/watch?v=AGVXJ-TIv3Y

ssh key generation
ssh-keygen -t ed25519 -C "sunny.samantara1@gmail.com" -f ~/.ssh/github
ssh-add ~/.ssh/github
eval "$(ssh-agent -s)"
ssh -T git@github.com
git remote -v

git remote set-url origin git@github.com:sunnysamantara/nixos-config.git

Resources:
NixOS: 1. NixOS Website: https://nixos.org/ 2. NixOS Manual: https://nixos.org/manual/nixos/stable/ 3. NixOS Packages & Options: https://search.nixos.org/packages 4. NixOS Wiki: https://nixos.wiki/wiki/Main_Page
Home-Manager: 5. Home-Manager: https://github.com/nix-community/home... 6. Home-Manager Manual: https://nix-community.github.io/home-... 7. Home-Manager Appendix A: https://nix-community.github.io/home-... 8. Home-Manager Appendix B: https://nix-community.github.io/home-...
Examples: 9. Personal Flake: https://github.com/MatthiasBenaets/ni... 10. List of reference configurations: https://nixos.wiki/wiki/Configuration...
Extras: 11. NixOS Learn: https://nixos.org/learn.html/ 12. Nix Pills: https://nixos.org/guides/nix-pills/

    https://nixos-and-flakes.thiscute.world

Meta + G
MEta+W
meta+ctrl+esc
meta+esc

    plasma-mager
    superfile
    zsh
    fonts konsole


    Commands

    nix flake check

    nix-channel --list

    nix --extra-experimental-features nix-command --extra-experimental-features flakes flake show

    nixos-rebuild


    1- install nixOs

    2- enable falkes
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    3- change hostname

    4- rebuild system
    sudo nixos-rebuild switch

    5 - rebuild with install bootloaler and change the hardwareconfig file
    nix flake update
    sudo nixos-rebuild switch --install-bootloader --flake .
    sudo rm -rf /boot/EFI/systemd
    sudo rm -rf /boot/EFI/BOOT/BOOTX64.EFI


    6 - rebuild home manger
    nix run github:nix-community/home-manager -- switch --flake .

    nix flake update
    export NIXPKGS_ALLOW_INSECURE=1

sudo nixos-rebuild switch --flake .
NIXPKGS_ALLOW_INSECURE=1 sudo -E nixos-rebuild switch --flake . --impure

sudo nix-collect-garbage -d
sudo nix-store --optimise

nix-shell -p ntfs3g --run "sudo ntfsfix --clear-dirty /dev/nvme0n1p5"

sudo nix-store --verify --check-contents --repair

env -u QT_QPA_PLATFORM_PLUGIN_PATH -u QT_PLUGIN_PATH spyder

C00l&unny

SS@547505

Qwertghjkl12#$%

nix run github:nix-community/nixos-anywhere -- --flake .#skullsaint --disk main /dev/nvme0n1 root@<ip>

Correct workflow

**1. Encrypt the existing plaintext files in place (first time only):**

```bash
cd /home/sunny/homeserver/secrets
nix-shell -p sops --run "sops -e -i hosts/acer-aspire.yaml"
nix-shell -p sops --run "sops -e -i hosts/skullsaint.yaml"
nix-shell -p sops --run "sops -e -i common.yaml"
nix-shell -p sops --run "sops -e -i users/sunny.yaml"
nix-shell -p sops --run "sops -e -i users/route.yaml"
```

`-e` = encrypt, `-i` = in-place. sops reads `.sops.yaml`, matches the path regex, and picks the right public keys (e.g. acer-aspire → `host_acer` + `yubikey`). Comments stay; only values become `ENC[AES256_GCM,...]`. No private key needed for encryption.

**2. Edit thereafter (human-readable):**

```bash
nix-shell -p sops --run "sops hosts/acer-aspire.yaml"   # opens decrypted in $EDITOR
```

**3. View decrypted without editing:**

```bash
nix-shell -p sops --run "sops --decrypt hosts/acer-aspire.yaml"
```

## Update keys (add a new host/user key)

1. Edit `.sops.yaml`: add the public key under `keys:` with an anchor, then add that anchor to the relevant `creation_rules` key_groups.
2. Re-encrypt every existing file so the new key can decrypt it:

```bash
nix-shell -p sops --run "sops updatekeys hosts/acer-aspire.yaml"
nix-shell -p sops --run "sops updatekeys common.yaml"
# ...repeat for each encrypted file
```

## Decryption key (still missing)

No private key exists locally (`~/.config/sops/age/keys.txt` and `/var/lib/sops-nix/key.txt` are absent). Encryption works, but **decrypting/viewing requires a private key**:

- YubiKey (public key already in `.sops.yaml`): keep it plugged in, run `nix-shell -p age-plugin-yubikey --run "age-plugin-yubikey"`.
- Or generate a user key: `age-keygen -o ~/.config/sops/age/keys.txt`, add its public key to `.sops.yaml`, then `sops updatekeys` on each file.

## Security note

The password hashes are currently **plaintext and untracked** in the working tree. After step 1 they're encrypted; commit only the encrypted files to the private repo (never plaintext).

## Before I proceed

- Which **new key** do you want to add (new host, new user, or a user age key)? I need the public key or the source to generate it.
- Do you have the **YubiKey** for decryption, or should I plan generating `~/.config/sops/age/keys.txt`?
- Do you want me to run the `sops -e -i` encryption for all five files, or just specific ones?

I'm in plan mode — nothing has been changed. Confirm and I'll execute.

### Option A — default location (simplest, no env var)

Put the private key at `~/.config/sops/age/keys.txt`; sops finds it automatically:

```bash
mkdir -p ~/.config/sops/age
# write the AGE-SECRET-KEY-1... line into ~/.config/sops/age/keys.txt
nix-shell -p sops --run "sops hosts/acer-aspire.yaml"
```

### Option B — explicit path via env var

`nix-shell -p sops` inherits your environment by default, so this works:

```bash
SOPS_AGE_KEY_FILE=/path/to/keys.txt nix-shell -p sops --run "sops hosts/acer-aspire.yaml"
```

or set it inside the run string:

```bash
nix-shell -p sops --run "SOPS_AGE_KEY_FILE=/path/to/keys.txt sops hosts/acer-aspire.yaml"
```

### Option C — direct key string

```bash
nix-shell -p sops --run "SOPS_AGE_KEY='AGE-SECRET-KEY-1...' sops hosts/acer-aspire.yaml"
```

### Key file format

One age X25519 identity per line; `#` lines are comments:

```
# created: 2026-...
# public key: age1npsqgr6r7st4xxkjffnulhncpwtw6upex8pj0s04yq8mx0faccwqq5gwts
AGE-SECRET-KEY-1...
```

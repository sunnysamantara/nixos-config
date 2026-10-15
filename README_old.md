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
  NixOS:
    1. NixOS Website: https://nixos.org/
    2. NixOS Manual: https://nixos.org/manual/nixos/stable/
    3. NixOS Packages & Options: https://search.nixos.org/packages
    4. NixOS Wiki: https://nixos.wiki/wiki/Main_Page
  Home-Manager:
    5. Home-Manager: https://github.com/nix-community/home...
    6. Home-Manager Manual: https://nix-community.github.io/home-...
    7. Home-Manager Appendix A: https://nix-community.github.io/home-...
    8. Home-Manager Appendix B: https://nix-community.github.io/home-...
  Examples:
    9. Personal Flake: https://github.com/MatthiasBenaets/ni... 
    10. List of reference configurations: https://nixos.wiki/wiki/Configuration...
  Extras:
    11. NixOS Learn: https://nixos.org/learn.html/
    12. Nix Pills: https://nixos.org/guides/nix-pills/

    
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

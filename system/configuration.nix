{
  config,
  pkgs,
  inputs,
  ...
}:
let
  user = "sunny";
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./login.nix
    ./yubikey.nix
    ./virt.nix
  ];

  services = {
    fstrim.enable = true;
  };




  # 1. Firewall Configuration for Packet / Quick Share

  programs.fuse.userAllowOther = true;
  #bluetooth



  # Enable networking
  networking.networkmanager.enable = true;
  #networking.useDHCP = true;




  # Enable CUPS to print documents.
  services.printing.enable = true;


  security.polkit.enable = true;
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    lshw
    libheif

 
    
    resvg
    # qpwgraph
    
    btop
    gdu
   
    

  ];


  


  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
  };

}

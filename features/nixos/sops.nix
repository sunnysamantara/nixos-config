{ inputs, ... }:
{
  flake.modules.nixos.sops = { config, lib, ... }: {
    sops = {
      age.keyFile = "/var/lib/sops-nix/key.txt";
      age.generateKey = true;
      defaultSopsFile = lib.mkDefault (inputs.nix-secrets + "/common.yaml");
      defaultSopsFormat = "yaml";
    };
  };
}

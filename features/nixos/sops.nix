{ inputs, ... }:
{
  flake.modules.nixos.sops = { config, ... }: {
    sops = {
      age.keyFile = "/var/lib/sops-nix/key.txt";
      age.generateKey = true;
      defaultSopsFile = inputs.nix-secrets + "/common.yaml";
      defaultSopsFormat = "yaml";
    };
  };
}

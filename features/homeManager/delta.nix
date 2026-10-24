{ ... }:
{
  flake.modules.homeManager.delta = { pkgs, inputs, ... }: {
    home.packages = [
      inputs.delta.packages.${pkgs.stdenv.hostPlatform.system}.delta
    ];
  };
}

{ ... }:
{
  flake.modules.homeManager.devenv = { ... }: {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    programs.devenv.enable = true;
  };
}

{ ... }:
{
  flake.modules.homeManager.kde = { inputs, pkgs, ... }: {
    # Core: expose plasma-manager and enable Plasma. Every other kde-*
    # feature relies on this one being present (kde-all pulls it in).
    imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

    programs.plasma = {
      enable = true;
      overrideConfig = true;
    };

    home.packages = [ pkgs.wayland-utils ];
  };
}

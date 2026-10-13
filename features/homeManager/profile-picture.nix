{ ... }:
{
  flake.modules.homeManager.profile-picture = { config, lib, ... }:
  let
    cfg = config.profile.picture;
  in
  {
    options.profile.picture = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Image shown as this user's avatar (~/.face and ~/.face.icon).";
    };

    config = lib.mkIf (cfg != null) {
      home.file.".face".source = cfg;
      home.file.".face.icon".source = cfg;
    };
  };
}

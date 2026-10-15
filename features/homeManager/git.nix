{ ... }:
{
  flake.modules.homeManager.git = { pkgs, ... }: {
    home.packages = [ pkgs.git-filter-repo ];

    programs.git = {
      enable = true;
      lfs.enable = true;
      signing = {
        format = "ssh";
        key = "~/.ssh/github.pub"; # public key
        signByDefault = true; # commit.gpgSign + tag.gpgSign
      };
      settings = {
        user = {
          name = "sunnysamantara";
          email = "sunny.samantara1@gmail.com";
        };
        init.defaultBranch = "main";
      };
    };

    programs.lazygit = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}

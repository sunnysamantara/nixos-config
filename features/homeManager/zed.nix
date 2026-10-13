{ ... }:
{
  flake.modules.homeManager.zed = { config, osConfig, pkgs, ... }: {
    # Ensure the LSPs are installed in your system/user profile
    home.packages = with pkgs; [
      zed-editor
      marksman # Markdown Language Server
      harper # Grammar and spell checker LSP
      nixd # Nix Language Server
      nixfmt # Nix formatter
    ];
    # Configure Zed settings directly via Home Manager
    programs.zed-editor = {
      enable = true;
      defaultEditor = true;
      extensions = [
        "markdown"
        "harper"
        "nix"
      ];
      userSettings = {
        format_on_save = "on";
        formatter = "auto";
        # window_decorations = "server";
        autosave = {
          after_delay = {
            milliseconds = 1000;
          };
        };
        search = {
          regex = true; # regex search on by default in buffer/project search
          whole_word = false;
          case_sensitive = false;
        };
        use_smartcase_search = true;
        cursor_blink = true;
        soft_wrap = "editor_width";
        minimap.show = "auto";
        indent_guides = {
          enabled = true;
          coloring = "indent_aware";
        };
        tabs = {
          file_icons = true;
          git_status = true;
        };
        language_models.open_router.api_url = "https://openrouter.ai/api/v1";
        agent.default_model = {
          provider = "open_router";
          model = "openrouter/auto";
        };
        project_panel.git_status = true;
        git.inline_blame.enabled = true;
        restore_on_startup = "last_session";
        session.restore_unsaved_buffers = true;
        preview_tabs.enabled = true;
        # Enable LSPs for Markdown files
        languages = {
          Markdown = {
            language_servers = [
              "marksman"
              "harper"
              "..." # Keeps default LSPs if any
            ];
            format_on_save = "on";
            soft_wrap = "preferred_line_length";
          };

          # Nix language configuration
          Nix = {
            language_servers = [
              "nixd"
              "!nil"
            ];
            format_on_save = "on";
            formatter = {
              external = {
                command = "nixfmt";
                arguments = [ ];
              };
            };
            tab_size = 2;
          };
        };

        # Customize Harper grammar/spell checker rules
        lsp = {
          harper = {
            settings = {
              "harper-ls" = {
                userDict = [ ]; # Add custom dictionary words here
                linters = {
                  spell_check = true;
                  spelled_numbers = false;
                  an_a = true;
                  sentence_capitalization = true;
                };
              };
            };
          };

          # nixd LSP settings
          nixd = {
            settings = {
              nixd = {
                formatting = {
                  command = [ "nixfmt" ];
                };
              # Derived from the user's actual home + the real hostname, so this
              # shared feature stays host/user-agnostic.
              nixpkgs = {
                expr = "import (builtins.getFlake \"${config.home.homeDirectory}/.dotfile\").inputs.nixpkgs { }";
              };
              options = {
                nixos.expr = "(builtins.getFlake \"${config.home.homeDirectory}/.dotfile\").nixosConfigurations.${osConfig.networking.hostName}.options";
                # NOTE: no home_manager.expr — this flake exports no
                # homeConfigurations output (HM is a NixOS module here), so a
                # reference to it is un-evaluable. Add one if you ever expose
                # homeConfigurations from flake.nix.
              };
              };
            };
          };
        };
      };
    };
  };
}
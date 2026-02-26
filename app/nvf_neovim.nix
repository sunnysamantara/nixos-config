{
  config,
  pkgs,
  ...
}: {
  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        autopairs.nvim-autopairs.enable = true;
        autocomplete.blink-cmp = {
          enable = true;
          friendly-snippets.enable = true;
          sourcePlugins.spell.enable = true;
        };
        # binds.hardtime-nvim.enable = true ;
        binds.whichKey = {
          enable = true;
          setupOpts = {
            notify = true;
            preset = "modern"; # classic, modern, helix
            win.border = "rounded";
          };
        };
        clipboard = {
          enable = true;
          providers.wl-copy.enable = true;
          registers = "unnamed,unnamedplus";
        };
        comments.comment-nvim.enable = true;
        formatter.conform-nvim = {
          enable = true;
          setupOpts.formatters_by_ft = {
            lua = ["stylua"];
            python = [
              "isort"
              "black"
            ];
            nix = ["nixfmt"];
          };
        };
        git.enable = true;
        keymaps = [
          {
            desc = "Format file";
            key = "ff";
            mode = [
              "n"
              "v"
            ];
            lua = true;
            action = "function() require('conform').format() end";
          }
        ];
        languages = {
          enableFormat = true;
          enableTreesitter = true;
          nix.enable = true;
          python.enable = true;
          html.enable = true;
          java.enable = true;
          json.enable = true;
          lua.enable = true;
          markdown = {
            enable = true;
            treesitter.enable = true;
            lsp.enable = true;
          };
          css = {
            enable = true;
            format.enable = true;
          };
        };
        lsp = {
          enable = true;
          lspconfig.enable = true;
        };
        options = {
          tabstop = 2;
          shiftwidth = 2;
        };
        searchCase = "smart";
        spellcheck = {
          enable = true;
          languages = ["en"];
        };
        startPlugins = [pkgs.vimPlugins.render-markdown-nvim];
        statusline.lualine.enable = true;
        syntaxHighlighting = true;
        theme = {
          enable = true;
          name = "gruvbox";
          style = "dark";
          transparent = true;
        };
        ui.colorizer.enable = true;
        viAlias = true;
        vimAlias = true;
      };
    };
  };
}

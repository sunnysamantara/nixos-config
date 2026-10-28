{ ... }:
{
  flake.modules.homeManager.opencode = { config, pkgs, ... }: {
    programs.opencode = {
      enable = true;
      extraPackages = with pkgs; [
        ripgrep
        fd
        fzf
      ];

      # No top-level `model` on purpose: pick one interactively with /models.
      # TUI theme is owned by the catppuccin integration (catppuccin.opencode).
      #
      # Self-hosted OmniRoute gateway (services/omniroute.nix on this host) as
      # an OpenAI-compatible provider. Models are auto-fetched from
      # OmniRoute's /v1/models endpoint at runtime (depends on providers
      # configured in the dashboard). The gateway key comes from sops
      # (users/sunny/sunny.nix declares sops.secrets.omniroute_api_key);
      # `{file:...}` is OpenCode's documented runtime file substitution,
      # so the value never lands in the generated /nix/store opencode.json.
      settings.provider.omniroute = {
        npm = "@ai-sdk/openai-compatible";
        name = "OmniRoute";
        options = {
          baseURL = "http://127.0.0.1:20128/v1";
          apiKey = "{file:${config.sops.secrets.omniroute_api_key.path}}";
        };
        models = { };
      };
    };
  };
}

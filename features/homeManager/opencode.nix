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
      # an OpenAI-compatible provider. `omniroute/auto` is the auto-combo.
      # The gateway key comes from sops (users/sunny/sunny.nix declares
      # sops.secrets.omniroute_api_key); `{file:...}` is OpenCode's documented
      # runtime file substitution, so the value never lands in the generated
      # /nix/store opencode.json.
      settings.provider.omniroute = {
        npm = "@ai-sdk/openai-compatible";
        name = "OmniRoute";
        options = {
          baseURL = "http://127.0.0.1:20128/v1";
          apiKey = "{file:${config.sops.secrets.omniroute_api_key.path}}";
        };
        # Static curated list of OmniRoute's virtual `auto/*` routing models.
        # The full catalogue is dynamic (it depends on providers configured in
        # the dashboard); dump the exact ids from the running container with
        # `sudo podman exec omniroute omniroute setup-opencode --dry-run`.
        models = {
          auto = {
            name = "Auto (best combo)";
          };
          "auto/best-coding" = {
            name = "Auto · best coding";
          };
          "auto/best-reasoning" = {
            name = "Auto · best reasoning";
          };
          "auto/best-fast" = {
            name = "Auto · best fast";
          };
          "auto/best-free" = {
            name = "Auto · best free";
          };
          "auto/coding" = {
            name = "Auto · coding";
          };
          "auto/fast" = {
            name = "Auto · fast";
          };
          "auto/cheap" = {
            name = "Auto · cheap";
          };
          "auto/smart" = {
            name = "Auto · smart";
          };
        };
      };
    };
  };
}

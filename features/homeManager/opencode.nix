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


      # Self-hosted OmniRoute gateway (services/omniroute.nix on this host) as
      # an OpenAI-compatible provider. Models are auto-fetched from
      # OmniRoute's /v1/models endpoint at runtime.
      settings.provider.omniroute = {
        npm = "@ai-sdk/openai-compatible";
        name = "OmniRoute";
        options = {
          baseURL = "http://127.0.0.1:20128/v1";
          apiKey = "{file:${config.sops.secrets.omniroute_api_key.path}}";
        };
        models = {
          "kr/claude-sonnet-4.5" = {
            name = "Claude Sonnet 4.5 (OmniRoute)";
          };
          "kr/claude-haiku-4.5" = {
            name = "Claude Haiku 4.5 (OmniRoute)";
          };
          "kr/deepseek-3.2" = {
            name = "DeepSeek 3.2 (OmniRoute)";
          };
          "kr/minimax-m2.5" = {
            name = "MiniMax M2.5 (OmniRoute)";
          };
          "kr/glm-5" = {
            name = "GLM-5 (OmniRoute)";
          };
          "kr/qwen3-coder-next" = {
            name = "Qwen3 Coder Next (OmniRoute)";
          };
          "agy/claude-sonnet-4-6" = {
            name = "Claude Sonnet 4.6 (OmniRoute)";
          };
          "agy/claude-opus-4-6-thinking" = {
            name = "Claude Opus 4.6 Thinking (OmniRoute)";
          };
          "agy/gemini-3.8-flash-high" = {
            name = "Gemini 3.8 Flash High (OmniRoute)";
          };
          "agy/gemini-3.8-flash-medium" = {
            name = "Gemini 3.8 Flash Medium (OmniRoute)";
          };
          "agy/gemini-3.8-flash-low" = {
            name = "Gemini 3.8 Flash Low (OmniRoute)";
          };
          "agy/gemini-3.1-flash-lite" = {
            name = "Gemini 3.1 Flash Lite (OmniRoute)";
          };
          "agy/gpt-oss-120b-medium" = {
            name = "GPT-OSS 120B Medium (OmniRoute)";
          };
        };
      };
    };

    # Electron desktop client. nixpkgs pins it to the same version as
    # pkgs.opencode (2.0.32) and bundles that CLI as its sidecar, so the TUI and
    # the desktop app never drift. A packaged build reads the real
    # ~/.config/opencode/opencode.json, so the omniroute provider (and the
    # {file:...} sops key) apply to both.
    home.packages = [
      pkgs.opencode-desktop
      # extraPackages above only extend the CLI wrapper's PATH; the Electron app
      # inherits the Plasma session PATH instead.
      pkgs.fd
      pkgs.fzf
    ];
  };
}

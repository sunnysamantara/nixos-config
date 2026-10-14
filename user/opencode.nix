{ pkgs, ... }:

{
  programs.opencode = {
    enable = true;

    # Enable integration with shell environments (aliases, environment variables)
    # enableBashIntegration = true;
    # enableZshIntegration = true;
    # enableFishIntegration = true;

    # Good-to-have configuration defaults
    settings = {
      # Theme and UI preferences
      theme = "dark";
      editor = {
        vimMode = true; # Set to true if you prefer Vim keybindings
        fontSize = 14;
        # fontFamily = "Fira Code";
        lineNumbers = true;
      };

      # Default LLM Provider Settings
      # Note: Store actual API keys in environment variables (e.g., sops-nix/agenix)
      openrouter = {
        package = "@opencode/ai/providers/openai-compatible";
        env = [ "OPENROUTER_API_KEY" ]; # Reads from your shell environment
        settings = {
          baseURL = "https://openrouter.ai/api/v1";
        };
        models = {
          "meta-llama/llama-3-8b-instruct:free" = {
            name = "Llama 3 8B (Free)";
          };
        };
      };

      # Context and behavior settings
      autostart = false;
      formatOnSave = true;
      telemetry = false; # Disable usage metrics
    };
  };

  # Make sure dependent tools (git, ripgrep, etc.) are available for OpenCode
  home.packages = with pkgs; [
    ripgrep # Fast file search for code indexing
    fd # Fast directory traversal
    fzf # Fuzzy finding capabilities
  ];
}

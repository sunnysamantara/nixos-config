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
        fontFamily = "Fira Code";
        lineNumbers = true;
      };

      # Default LLM Provider Settings
      # Note: Store actual API keys in environment variables (e.g., sops-nix/agenix)
      # providers = {
      #   openai = {
      #     defaultModel = "gpt-4o";
      #   };
      #   anthropic = {
      #     defaultModel = "claude-3-5-sonnet-20241022";
      #   };
      # };

      # Context and behavior settings
      autostart = false;
      formatOnSave = true;
      telemetry = false; # Disable usage metrics
    };
  };

  # Make sure dependent tools (git, ripgrep, etc.) are available for OpenCode
  #   home.packages = with pkgs; [
  #     ripgrep # Fast file search for code indexing
  #     fd # Fast directory traversal
  #     fzf # Fuzzy finding capabilities
  #   ];
}

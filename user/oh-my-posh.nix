{
  config,
  pkgs,
  ...
}: {
  programs.oh-my-posh = {
    enable = true;
    useTheme = null; # using custom settings below
    settings = {
      "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
      final_space = true;
      version = 4;

      palette = {
        os = "#ACB0BE";
        closer = "p:os";
        pink = "#F5BDE6";
        lavender = "#B7BDF8";
        blue = "#8AADF4";
      };

      blocks = [
        # ── Block 1: Left prompt (os / session / path / git) ──────────────
        {
          alignment = "left";
          type = "prompt";
          segments = [
            {
              type = "os";
              style = "plain";
              foreground = "p:os";
              template = "{{.Icon}} ";
            }
            {
              type = "session";
              style = "plain";
              foreground = "p:blue";
              template = "[{{ if .SSHSession }}\ueba9 {{ end }}{{ .UserName }}@{{ .HostName }}] ";
            }
            {
              type = "path";
              style = "plain";
              foreground = "p:pink";
              template = "[{{ .Path }}] ";
              options = {
                folder_icon = "..\ue5fe..";
                home_icon = "~";
                style = "full";
              };
            }
            {
              type = "git";
              style = "plain";
              foreground = "p:lavender";
              foreground_templates = [
                "{{ if or (.Working.Changed) (.Staging.Changed) }}#FFEB3B{{ end }}"
                "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#FFCC80{{ end }}"
                "{{ if gt .Ahead 0 }}#B388FF{{ end }}"
                "{{ if gt .Behind 0 }}#B388FB{{ end }}"
              ];
              template = "[{{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} {{ .StashCount }}{{ end }}] ";
              options = {
                fetch_status = true;
                # fetch_upstream_icon = true;
              };
            }
          ];
        }

        # ── Block 2: Right prompt (execution time) ─────────────────────────
        {
          alignment = "right";
          type = "prompt";
          segments = [
            {
              type = "executiontime";
              style = "plain";
              foreground = "p:pink";
              template = "[{{ .FormattedMs }}] ";
              options = {
                style = "roundrock";
                threshold = 0;
                always_enabled = true;
              };
            }
            {
              type = "time";
              style = "plain";
              foreground = "p:lavender";
              template = "[{{ .CurrentDate | date .Format }}] ";
              options = {
                time_format = "Mon, 3:04PM";
              };
            }
          ];
        }

        # ── Block 3: Second line prompt character ──────────────────────────
        {
          alignment = "left";
          type = "prompt";
          newline = true;
          segments = [
            {
              type = "text";
              style = "plain";
              foreground = "p:blue";
              template = "[]";
            }
          ];
        }
      ];
    };
  };
}

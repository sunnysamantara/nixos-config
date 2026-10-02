{ config, lib, pkgs, ... }:

# Nix has no \uXXXX string escapes, so we derive the ESC character from JSON.
let
  esc = builtins.fromJSON "\"\\u001b\"";
in
{
  programs.fastfetch = {
    enable = true;

    settings = {

      # ── Logo ──────────────────────────────────────────────────────────────
      # The PNG must live at ~/.config/fastfetch/cachyos-logo-dark.png.
      # Manage it with home.file or place it manually.
      logo = {
        type   = "file";
        source = "zoro.txt";
        padding = {
          top   = 2;
          left  = 2;
          right = 2;
        };
      };

      # ── Display ───────────────────────────────────────────────────────────
      display = {
        color.keys  = "yellow";
        separator   = "";
        brightColor = false;
        # {$1} … {$5} are referenced inside module key/format strings below.
        constants = [
          "─────────────────────────────────────────────────────────" # {$1} horizontal rule
          "${esc}[58D"  # {$2} cursor ← 58 columns
          "${esc}[58C"  # {$3} cursor → 58 columns
          "${esc}[57C"  # {$4} cursor → 57 columns
          "│"           # {$5} vertical bar
        ];
      };

      # ── Modules ───────────────────────────────────────────────────────────
      modules = [
        "break"

        # Title banner ─────────────────────────────────────────────────────
        {
          type   = "version";
          key    = "╭─────────────┬─{$1}╮${esc}[42D";
          format = "${esc}[1m{#keys} {1} - {2} ";
        }

        # System overview (beside the logo) ────────────────────────────────
        {
          type = "os";
          key  = "{$5}{#36}{icon}{#white}  ${esc}[s{#34}{sysname}${esc}[u${esc}[10C{#keys}{$5}{$3}{#keys}{$5}{$2}";
        }
        {
          type = "kernel";
          key  = "{$5}{#36}{icon}{#white}  ${esc}[s{#34}Kernel${esc}[u${esc}[10C{#keys}{$5}{$3}{#keys}{$5}{$2}";
        }
        {
          type = "packages";
          key  = "{$5}{#36}{icon}{#white}  ${esc}[s{#34}Packages{#37}  {#keys}{$5} {$4}{#keys}{$5}{$2}";
        }
        {
          type             = "localip";
          key              = "{$5}{#36}{icon}{#white}  {#34}Local IP{#37}  {#keys}{$5}{$3}{$5}{$2}";
          showIpv4         = false;
          showIpv6         = false;
          showMac          = false;
          showLoop         = false;
          showPrefixLen    = true;
          showMtu          = false;
          showSpeed        = true;
          showFlags        = false;
          compact          = true;
          defaultRouteOnly = true;
          showAllIps       = false;
          namePrefix       = "";
        }
        {
          type = "locale";
          key  = "{$5}{#36}{icon}  {#34}Locale{#37}    {#keys}{$5}{$3}{#keys}{$5}{$2}";
        }
        # Separator between the logo-side panel and the section boxes
        {
          type   = "custom";
          key    = "├─────────────┴─{$1}┤";
          format = "";
        }

        # ── Hardware ────────────────────────────────────────────────────────
        {
          type   = "custom";
          key    = "{$5}{#white}╭────────────┬{$1}╮{#keys}{$5}${esc}[36D";
          format = "{#bright_white} Hardware ";
        }
        {
          type = "board";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Board{#37}    {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type   = "bios";
          key    = "{$5}{#white}{$5}{#white}╰─ {#34}Bios{#37}     {$5}{$4}{$5}{#keys}{$5}{$2}";
          format = "{4} ({1})";
        }
        {
          type = "chassis";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Chassis{#37}  {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type            = "cpu";
          key             = "{$5}{#white}{$5}{#36}{icon}  {#34}CPU{#37}      {$5}{$4}{$5}{#keys}{$5}{$2}";
          format          = "{name} @{freq-max}";
          showPeCoreCount = false;
        }
        {
          type            = "gpu";
          key             = "{$5}{#white}{$5}{#36}{icon}  {#34}GPU{#37}      {$5}{$4}{$5}{#keys}{$5}{$2}";
          temp            = true;
          showPeCoreCount = false;
        }
        {
          type   = "gpu";
          key    = "{$5}{#white}{$5}{#white}╰─ {#34}Driver{#37}   {$5}{$4}{$5}{#keys}{$5}{$2}";
          format = "{driver}";
        }
        {
          type        = "display";
          key         = "{$5}{#white}{$5}{#36}{icon}  {#34}Display{#37}  {$5}{$4}{$5}{#keys}{$5}{$2}";
          compactType = "original-with-refresh-rate";
        }
        {
          type = "sound";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Sound{#37}    {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type   = "custom";
          key    = "{$5}{#white}╰────────────┴{$1}╯{#keys}{$5}";
          format = "";
        }

        # ── Memory & Storage ────────────────────────────────────────────────
        {
          type   = "custom";
          key    = "{$5}{#white}╭────────────┬{$1}╮{#keys}{$5}${esc}[36D";
          format = "{#bright_white} Memory & Storage ";
        }
        {
          type = "memory";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}RAM{#37}      {$5}{$4}{$5}{#keys}{$5}{$2}";
          percent = {
            type   = 3; # number + bar + percentage
            green  = 30;
            yellow = 70;
          };
        }
        {
          type = "swap";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}SWAP{#37}     {$5}{$4}{$5}{#keys}{$5}{$2}";
          percent = {
            type   = 3;
            green  = 30;
            yellow = 70;
          };
        }
        {
          type = "disk";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}DISK{#37}     {$5}{$4}{$5}{#keys}{$5}{$2}";
          percent = {
            type   = 3;
            green  = 30;
            yellow = 70;
          };
        }
        {
          type = "battery";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Battery{#37}  {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type   = "custom";
          key    = "{$5}{#white}╰────────────┴{$1}╯{#keys}{$5}";
          format = "";
        }

        # ── Desktop ─────────────────────────────────────────────────────────
        {
          type   = "custom";
          key    = "{$5}{#white}╭────────────┬{$1}╮{#keys}{$5}${esc}[36D";
          format = "{#bright_white} Desktop ";
        }
        {
          type                 = "de";
          key                  = "{$5}{#white}{$5}{#36}{icon}  {#34}Desktop{#37}  {$5}{$4}{$5}{#keys}{$5}{$2}";
          slowVersionDetection = false;
        }
        {
          type         = "wm";
          key          = "{$5}{#white}{$5}{#36}{icon}  {#34}Session{#37}  {$5}{$4}{$5}{#keys}{$5}{$2}";
          detectPlugin = false;
        }
        {
          type   = "theme";
          key    = "{$5}{#white}{$5}{#36}{icon}  {#34}Qt Theme{#37} {$5}{$4}{$5}{#keys}{$5}{$2}";
          format = "{1}";
        }
        {
          type   = "theme";
          key    = "{$5}{#white}{$5}{#36}{icon}  {#34}GTK Theme{#37}{$5}{$4}{$5}{#keys}{$5}{$2}";
          format = "{2}";
        }
        {
          type = "icons";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Icon Set{#37} {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type = "font";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Font{#37}     {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type = "cursor";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Cursor{#37}   {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type = "lm";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}LoginMgr{#37} {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type = "bootmgr";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}BootMgr{#37}  {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type   = "custom";
          key    = "{$5}{#white}╰────────────┴{$1}╯{#keys}{$5}";
          format = "";
        }

        # ── Terminal ────────────────────────────────────────────────────────
        {
          type   = "custom";
          key    = "{$5}{#white}╭────────────┬{$1}╮{#keys}{$5}${esc}[37D";
          format = "{#bright_white} Terminal ";
        }
        {
          type = "shell";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Shell{#37}    {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type = "terminal";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Terminal{#37} {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type = "terminalfont";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Term Font{#37}{$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type = "terminaltheme";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Colors{#37}   {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type   = "custom";
          key    = "{$5}{#white}╰────────────┴{$1}╯{#keys}{$5}";
          format = "";
        }

        # ── Uptime ──────────────────────────────────────────────────────────
        {
          type   = "custom";
          key    = "{$5}{#white}╭────────────┬{$1}╮{#keys}{$5}${esc}[36D";
          format = "{#bright_white} Uptime ";
        }
        {
          type = "uptime";
          key  = "{$5}{#white}{$5}{#36}{icon}  {#34}Uptime{#37}   {$5}{$4}{$5}{#keys}{$5}{$2}";
        }
        {
          type   = "datetime";
          key    = "{$5}{#white}{$5}{#36}{icon}  {#34}Fetched{#37}  {$5}{$4}{$5}{#keys}{$5}{$2}";
          format = "{day-pretty}-{month-pretty}-{year} {hour-pretty}:{minute-pretty}:{second-pretty} {timezone-name}";
        }
        # Uncomment to show OS install age (root filesystem creation date):
        # {
        #   type    = "disk";
        #   key     = "{$5}{#white}{$5} OS Age    {$5}{$4}{$5}{#keys}{$5}{$2}";
        #   folders = "/";
        #   format  = "{create-time:10} [{days} days]";
        # }
        {
          type   = "custom";
          key    = "{$5}{#white}╰────────────┴{$1}╯{#keys}{$5}";
          format = "";
        }

        # Colour swatch row ──────────────────────────────────────────────────
        {
          type   = "custom";
          key    = "{$5} {$3}             {$5}{$2}";
          format = "{#bright_yellow}󰮯{#dim_white} ⚬ ⚬ ⚬ ⚬ ⚬ ⚬ ⚬ ⚬ ⚬ ⚬ {#36} 󰊠 {#35} 󰊠 {#34} 󰊠 {#33} 󰊠 {#32} 󰊠 {#31} 󰊠";
        }

        # Bottom border ──────────────────────────────────────────────────────
        {
          type   = "custom";
          key    = "╰───────────────{$1}╯";
          format = "";
        }
      ];
    };
  };
}

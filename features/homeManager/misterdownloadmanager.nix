{ ... }:
{
  # Mister Download Manager (MDM): segmented download manager, torrent client, video
  # and gallery downloader. Installed as a prebuilt AppImage that is unpacked so all
  # four of its programs are usable (see pkgs/misterdownloadmanager/default.nix).
  #
  # This feature owns everything the app needs to be *the* downloader:
  #   - the helper programs it drives (7-Zip for 7z/RAR, ffmpeg, yt-dlp, gallery-dl);
  #   - the default handlers for magnet links and .torrent files;
  #   - the browsers' native-messaging manifests (needed for browser capture);
  #   - its MCP server, so AI assistants can drive the running app.
  flake.modules.homeManager.misterdownloadmanager =
    { pkgs, lib, ... }:
    let
      # Upstream's own manifests (what `misterdownloadmanager-nmhost --register`
      # writes), except `path` is the store path of the program.
      nmhost = "${pkgs.misterdownloadmanager}/bin/misterdownloadmanager-nmhost";

      firefoxManifest = pkgs.writeText "com.misterdownloadmanager.host.firefox.json" (
        builtins.toJSON {
          name = "com.misterdownloadmanager.host";
          description = "Mister Download Manager";
          path = nmhost;
          type = "stdio";
          allowed_extensions = [ "integration@misterdownloadmanager.com" ];
        }
      );

      chromiumManifest = pkgs.writeText "com.misterdownloadmanager.host.chromium.json" (
        builtins.toJSON {
          name = "com.misterdownloadmanager.host";
          description = "Mister Download Manager";
          path = nmhost;
          type = "stdio";
          allowed_origins = [
            "chrome-extension://oogbclbbninliongijffeeggalppliok/" # loaded unpacked
            "chrome-extension://ejoleppdfgjdndddcjoehopknmlglojp/" # store release
          ];
        }
      );

      # Chromium-family browsers whose profile dirs exist on this machine; MDM
      # itself registers the same set on startup, so this only has to cover the
      # window between a rebuild and the app's first launch.
      chromiumConfigDirs = [
        "chromium"
        "BraveSoftware/Brave-Browser"
        "net.imput.helium"
      ];

      # MDM finds ffmpeg and 7-Zip on PATH, but yt-dlp and gallery-dl it only takes
      # from its own download folder (`<data dir>/tools/<helper>/<version>/`) or
      # from this file, which its Helpers window writes when you pick your own copy
      # (crates/tools/src/chosen.rs upstream). Naming the store copies here means
      # nothing is downloaded at run time and the helpers move with
      # `nix flake update`; delete the file (or forget the helper in Helpers…) and
      # MDM falls back to managing its own copies again.
      chosenHelpers = pkgs.writeText "misterdownloadmanager-programs.json" (
        builtins.toJSON {
          "yt-dlp" = {
            version = pkgs.yt-dlp.version;
            exe = "${pkgs.yt-dlp}/bin/yt-dlp";
          };
          "gallery-dl" = {
            version = pkgs.gallery-dl.version;
            exe = "${pkgs.gallery-dl}/bin/gallery-dl";
          };
        }
      );
    in
    {
      home.packages = with pkgs; [
        misterdownloadmanager
        _7zz # 7z / RAR extraction; MDM cannot self-install this one
        ffmpeg # video+audio merge, HLS
        yt-dlp # video pages and playlists
        gallery-dl # image galleries
      ];

      # Browser capture: the extension hands links to the host below, which then
      # talks to the running app.
      #
      # These are deliberately *copies*, written by activation, and not
      # `home.file` symlinks: MDM re-runs `nmhost --register` on every start, and
      # writing through a symlink into the read-only store aborts its setup with
      # "Read-only file system (os error 30)" — the app then reports browser
      # integration as not set up. A plain file gets rewritten with the identical
      # content and the app is happy.
      home.activation.misterdownloadmanagerBrowsers =
        lib.hm.dag.entryAfter [ "writeBoundary" ] (
          ''
            run ${pkgs.coreutils}/bin/install -Dm644 ${firefoxManifest} \
              "$HOME/.mozilla/native-messaging-hosts/com.misterdownloadmanager.host.json"
          ''
          + lib.concatMapStrings (dir: ''
            run ${pkgs.coreutils}/bin/install -Dm644 ${chromiumManifest} \
              "$HOME/.config/${dir}/NativeMessagingHosts/com.misterdownloadmanager.host.json"
          '') chromiumConfigDirs
        );

      # The helper choice MDM reads (see `chosenHelpers` above). Also a copy, not a
      # symlink, for the same reason.
      home.activation.misterdownloadmanagerHelpers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.coreutils}/bin/install -Dm644 ${chosenHelpers} \
          "''${XDG_DATA_HOME:-$HOME/.local/share}/misterdownloadmanager/tools/programs.json"
      '';

      # Default downloader: magnet links and .torrent files open in MDM. The
      # handler comes from the package's own .desktop entry (MimeType= line).
      #
      # The user's ~/.config/mimeapps.list has accumulated many associations from
      # desktop use. Home Manager's `checkLinkTargets` aborts the *whole*
      # activation if an existing mimeapps.list would be clobbered (it did, on
      # 2026-11-18 — blocking every HM-managed file including Konveyor). Mirror
      # all of those associations here so the generated file is a superset, and
      # force the two targets so HM can own them without failing.
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/magnet" = [ "misterdownloadmanager.desktop" ];
          "application/x-bittorrent" = [ "misterdownloadmanager.desktop" ];
          "application/json" = [ "dev.zed.Zed.desktop" ];
          "application/x-extension-htm" = [ "firefox.desktop" ];
          "application/x-extension-html" = [ "firefox.desktop" ];
          "application/x-extension-shtml" = [ "firefox.desktop" ];
          "application/x-extension-xht" = [ "firefox.desktop" ];
          "application/x-extension-xhtml" = [ "firefox.desktop" ];
          "application/xhtml+xml" = [ "firefox.desktop" ];
          "text/html" = [ "brave-browser.desktop" ];
          "text/markdown" = [ "dev.zed.Zed.desktop" ];
          "text/plain" = [ "dev.zed.Zed.desktop" ];
          "text/x-python" = [ "dev.zed.Zed.desktop" ];
          "x-scheme-handler/bitwarden" = [ "bitwarden.desktop" ];
          "x-scheme-handler/chrome" = [ "firefox.desktop" ];
          "x-scheme-handler/gitkraken" = [ "gitkraken.desktop" ];
          "x-scheme-handler/http" = [ "brave-browser.desktop" ];
          "x-scheme-handler/https" = [ "brave-browser.desktop" ];
          "x-scheme-handler/jetbrains" = [ "jetbrainsd.desktop" ];
          "x-scheme-handler/mailto" = [ "brave-browser.desktop" ];
          "x-scheme-handler/notion" = [ "notion-app-enhanced.desktop" ];
          "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
          "x-scheme-handler/webcal" = [ "brave-browser.desktop" ];
          "x-scheme-handler/opencode" = [ "ai.opencode.desktop.desktop" ];
        };
        associations.added = {
          "application/json" = [ "dev.zed.Zed.desktop" ];
          "application/x-extension-htm" = [ "firefox.desktop" "zen.desktop" ];
          "application/x-extension-html" = [ "firefox.desktop" "zen.desktop" ];
          "application/x-extension-shtml" = [ "firefox.desktop" "zen.desktop" ];
          "application/x-extension-xht" = [ "firefox.desktop" "zen.desktop" ];
          "application/x-extension-xhtml" = [ "firefox.desktop" "zen.desktop" ];
          "application/xhtml+xml" = [ "firefox.desktop" "zen.desktop" ];
          "text/html" = [ "brave-browser.desktop" "firefox.desktop" "zen.desktop" ];
          "text/markdown" = [ "dev.zed.Zed.desktop" ];
          "text/plain" = [ "dev.zed.Zed.desktop" "nvim.desktop" ];
          "text/x-python" = [ "dev.zed.Zed.desktop" "conda-spyder_spyder-6-conda.desktop" ];
          "x-scheme-handler/bitwarden" = [ "Bitwarden.desktop" ];
          "x-scheme-handler/chrome" = [ "firefox.desktop" "zen.desktop" ];
          "x-scheme-handler/gitkraken" = [ "gitkraken.desktop" ];
          "x-scheme-handler/http" = [ "brave-browser.desktop" "firefox.desktop" "zen.desktop" ];
          "x-scheme-handler/https" = [ "brave-browser.desktop" "firefox.desktop" "zen.desktop" ];
          "x-scheme-handler/jetbrains" = [ "jetbrainsd.desktop" ];
          "x-scheme-handler/mailto" = [ "brave-browser.desktop" ];
          "x-scheme-handler/notion" = [ "notion-app-enhanced.desktop" ];
          "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
          "x-scheme-handler/webcal" = [ "brave-browser.desktop" ];
        };
      };

      xdg.configFile."mimeapps.list".force = true;
      xdg.dataFile."applications/mimeapps.list".force = true;

      # MCP server: list, add, pause and remove downloads from OpenCode & co.
      # `programs.opencode.enableMcpIntegration` (features/homeManager/opencode.nix)
      # merges this into OpenCode's own `mcp` settings.
      programs.mcp = {
        enable = true;
        servers.misterdownloadmanager = {
          command = "${pkgs.misterdownloadmanager}/bin/misterdownloadmanager-mcp";
        };
      };
    };
}

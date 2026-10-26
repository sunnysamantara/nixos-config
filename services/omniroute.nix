{ ... }:
{
  # OmniRoute (https://github.com/diegosouzapw/OmniRoute) — self-hosted AI
  # gateway / OpenAI-compatible router, run as an OCI container under rootful
  # podman. Loopback-only: the dashboard/API is never exposed to the LAN, so no
  # firewall change is needed.
  #
  # Server-side secrets live in the host sops file (secrets/hosts/<host>.yaml)
  # under `omniroute:`; sops renders them into a root-only env file at
  # activation and podman reads it with `--env-file` (see `environmentFiles`).
  # Nothing secret ever ends up in the Nix store.
  flake.services.omniroute = { config, ... }: {
    virtualisation.podman.enable = true;

    virtualisation.oci-containers = {
      backend = "podman";
      containers.omniroute = {
        # Pin an immutable SemVer tag; bump deliberately (see AGENTS.md).
        image = "docker.io/diegosouzapw/omniroute:3.8.52";

        ports = [ "127.0.0.1:20128:20128" ];

        # The image runs as uid/gid 1000 (`node`), so a named volume (created
        # by podman, owned by the image's user) is required for the SQLite DB,
        # provider credentials and `server.env`.
        volumes = [ "omniroute-data:/app/data" ];

        environment = {
          DATA_DIR = "/app/data";
          PORT = "20128";
          # Require a gateway key on /v1 (upstream default is false).
          REQUIRE_API_KEY = "true";
          # The image's 1024 MB floor only suits the dashboard; the standalone
          # launcher appends --max-old-space-size=<this value>.
          OMNIROUTE_MEMORY_MB = "4096";
        };

        # Rendered by sops-nix at activation: /run/secrets/rendered/omniroute.env
        environmentFiles = [ config.sops.templates."omniroute.env".path ];

        pull = "missing";

        # Upstream graceful-shutdown guidance (SSE streams drain on SIGTERM);
        # the module's own TimeoutStopSec is 120 by default.
        extraOptions = [ "--stop-timeout=40" ];
      };
    };

    # --- Secrets (secrets/hosts/<host>.yaml -> `omniroute:` map) -------------
    # Declaring them here means any host that enables this service must carry
    # the keys in its host sops file, otherwise activation fails loudly.
    sops.secrets."omniroute/jwt_secret" = { };
    sops.secrets."omniroute/api_key_secret" = { };
    sops.secrets."omniroute/ws_bridge_secret" = { };
    sops.secrets."omniroute/initial_password" = { };

    sops.templates."omniroute.env" = {
      mode = "0400";
      content = ''
        JWT_SECRET=${config.sops.placeholder."omniroute/jwt_secret"}
        API_KEY_SECRET=${config.sops.placeholder."omniroute/api_key_secret"}
        OMNIROUTE_WS_BRIDGE_SECRET=${config.sops.placeholder."omniroute/ws_bridge_secret"}
        INITIAL_PASSWORD=${config.sops.placeholder."omniroute/initial_password"}
      '';
    };
  };
}

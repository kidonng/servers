{ config, pkgs, ... }:

# https://github.com/NousResearch/hermes-agent/blob/2389564d83f5e31a293727f471631dab46601e2b/docker-compose.yml
let
  yaml = pkgs.formats.yaml { };
  # https://github.com/NousResearch/hermes-agent/blob/3d7dda4cf42176d587b459345c56236a26030324/cli-config.yaml.example
  hermesConfig = yaml.generate "hermes-config.yaml" {
    # Tried muse, but it frequently misses cache
    model.default = "deepseek/deepseek-v4-flash-vision-exp";
    compression = {
      threshold = 0.25; # compress at ~250K (for model with 1M context)
      target_ratio = 0.20; # keep ~50k (for model with 1M context)
    };
    memory.provider = "hindsight";
    streaming.enabled = true;
    # Allow access to Tailscale
    security.allow_private_urls = true;
  };
in
{
  sops.secrets = {
    "hermes/openrouter" = { };
    "hermes/telegram" = { };
  };

  # https://github.com/NousResearch/hermes-agent/blob/3d7dda4cf42176d587b459345c56236a26030324/website/docs/reference/environment-variables.md
  sops.templates."hermes-env" = {
    content = ''
      OPENROUTER_API_KEY=${config.sops.placeholder."hermes/openrouter"}
      TELEGRAM_BOT_TOKEN=${config.sops.placeholder."hermes/telegram"}

      TELEGRAM_ALLOWED_USERS=793708595
      TELEGRAM_HOME_CHANNEL=793708595

      FIRECRAWL_API_URL=http://localhost:3002
      BROWSER_CDP_URL=ws://localhost:9222
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/hermes-agent 0750 10000 10000 - -"
  ];

  virtualisation.quadlet = {
    containers = {
      hermes-agent = {
        containerConfig = {
          image = "docker.io/nousresearch/hermes-agent:latest";
          networks = [ "host" ];
          volumes = [
            "/var/lib/hermes-agent:/opt/data"
            "${hermesConfig}:/opt/data/config.yaml:ro"
          ];
          environmentFiles = [
            config.sops.templates."hermes-env".path
          ];
          environments = {
            # Allow /tmp to make life easier for agents
            HERMES_WRITE_SAFE_ROOT = "/opt/data:/tmp";
            # https://github.com/NousResearch/hermes-agent/blob/3d7dda4cf42176d587b459345c56236a26030324/plugins/memory/hindsight/README.md#environment-variables
            HINDSIGHT_MODE = "local_external";
          };
          exec = [ "gateway" "run" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };
    };
  };
}

{ config, ... }:

# https://github.com/firecrawl/firecrawl-docs/blob/7877f4cf689e1c1f48c8dc9f2c15fa895d93c410/contributing/self-host.mdx
# https://github.com/firecrawl/firecrawl/blob/6ff68d3b029089aed837a881d76616c2b52d711b/docker-compose.yaml
let
  commonEnv = {
    REDIS_URL = "redis://firecrawl-redis:6379";
    REDIS_RATE_LIMIT_URL = "redis://firecrawl-redis:6379";
    PLAYWRIGHT_MICROSERVICE_URL = "http://firecrawl-playwright:3000/scrape";

    POSTGRES_USER = "postgres";
    POSTGRES_PASSWORD = "postgres";
    POSTGRES_DB = "postgres";
    POSTGRES_HOST = "firecrawl-postgres";
    POSTGRES_PORT = "5432";
    USE_DB_AUTHENTICATION = "false";

    NUM_WORKERS_PER_QUEUE = "8";
    CRAWL_CONCURRENT_REQUESTS = "10";
    MAX_CONCURRENT_JOBS = "5";
    BROWSER_POOL_SIZE = "5";

    BULL_AUTH_KEY = "3a3ed2fd131030c8c197bfcc43a638c5";
    LOGGING_LEVEL = "INFO";
  };
in
{
  systemd.tmpfiles.rules = [
    "d /var/lib/firecrawl/postgres 0700 999 999 - -"
    "h /var/lib/firecrawl/postgres - - - - +C"
  ];

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) containers networks;
  in {
    networks.firecrawl = {
      networkConfig.driver = "bridge";
    };

    containers = {
      firecrawl-playwright = {
        containerConfig = {
          image = "ghcr.io/firecrawl/playwright-service:latest";
          networks = [ networks.firecrawl.ref ];
          environments = {
            PORT = "3000";
            PROXY_SERVER = "100.89.204.14:7890"; # dmit-lax
            MAX_CONCURRENT_PAGES = "10";
          };
          podmanArgs = [ "--cpus=2.0" ];
          memory = "4g";
          tmpfses = [ "/tmp/.cache:noexec,nosuid,size=1g" ];
          logDriver = "json-file";
          logOptions = [ "max-size=10m" "max-file=3" "compress=true" ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "5";
        };
      };

      firecrawl-api = {
        containerConfig = {
          image = "ghcr.io/firecrawl/firecrawl:latest";
          networks = [ networks.firecrawl.ref ];
          publishPorts = [ "3002:3002" ];
          environments = commonEnv // {
            HOST = "0.0.0.0";
            PORT = "3002";
            EXTRACT_WORKER_PORT = "3004";
            WORKER_PORT = "3005";
            NUQ_RABBITMQ_URL = "amqp://firecrawl-rabbitmq:5672";
            HARNESS_STARTUP_TIMEOUT_MS = "60000";
            ENV = "local";
          };
          ulimits = [ "nofile=65535:65535" ];
          exec = "node dist/src/harness.js --start-docker";
          podmanArgs = [ "--cpus=4.0" ];
          memory = "8g";
          logDriver = "json-file";
          logOptions = [ "max-size=10m" "max-file=3" "compress=true" ];
        };
        unitConfig = {
          Requires = [
            containers.firecrawl-redis.ref
            containers.firecrawl-playwright.ref
            containers.firecrawl-rabbitmq.ref
            containers.firecrawl-postgres.ref
          ];
          After = [
            containers.firecrawl-redis.ref
            containers.firecrawl-playwright.ref
            containers.firecrawl-rabbitmq.ref
            containers.firecrawl-postgres.ref
          ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };

      firecrawl-redis = {
        containerConfig = {
          image = "docker.io/library/redis:alpine";
          networks = [ networks.firecrawl.ref ];
          exec = "redis-server --bind 0.0.0.0";
          logDriver = "json-file";
          logOptions = [ "max-size=5m" "max-file=2" "compress=true" ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "5";
        };
      };

      firecrawl-rabbitmq = {
        containerConfig = {
          image = "docker.io/library/rabbitmq:3-management";
          networks = [ networks.firecrawl.ref ];
          # Erlang requires .erlang.cookie owner to match the running process user
          user = "rabbitmq";
          exec = "rabbitmq-server";
          healthCmd = "rabbitmq-diagnostics -q check_running";
          healthInterval = "5s";
          healthTimeout = "5s";
          healthRetries = 3;
          healthStartPeriod = "5s";
          logDriver = "json-file";
          logOptions = [ "max-size=5m" "max-file=2" "compress=true" ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "5";
        };
      };

      firecrawl-postgres = {
        containerConfig = {
          image = "ghcr.io/firecrawl/nuq-postgres:latest";
          networks = [ networks.firecrawl.ref ];
          volumes = [ "/var/lib/firecrawl/postgres:/var/lib/postgresql/data" ];
          environments = {
            POSTGRES_USER = "postgres";
            POSTGRES_PASSWORD = "postgres";
            POSTGRES_DB = "postgres";
          };
          logDriver = "json-file";
          logOptions = [ "max-size=10m" "max-file=3" "compress=true" ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "5";
        };
      };
    };
  };
}

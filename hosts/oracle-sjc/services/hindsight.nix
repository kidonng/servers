{ config, pkgs, ... }:

# https://github.com/vectorize-io/hindsight/blob/4b2041eb3de5c4235f4a3dd5619fc47cce782e29/hindsight-docs/docs/developer/installation.md
# https://github.com/vectorize-io/hindsight/blob/4b2041eb3de5c4235f4a3dd5619fc47cce782e29/hindsight-docs/docs/developer/configuration.md
# https://github.com/vectorize-io/hindsight/blob/4b2041eb3de5c4235f4a3dd5619fc47cce782e29/hindsight-docs/docs/developer/multilingual.md
# https://github.com/vectorize-io/hindsight/blob/4b2041eb3de5c4235f4a3dd5619fc47cce782e29/docker/docker-compose/pgroonga/docker-compose.yaml
# https://github.com/vectorize-io/hindsight/blob/4b2041eb3de5c4235f4a3dd5619fc47cce782e29/docker/docker-compose/pgroonga/Dockerfile
let
  postgresWithExts = pkgs.postgresql_17.withPackages (p: [
    p.pgvector
    p.pgroonga
  ]);

  hindsightPostgresEntrypoint = pkgs.writeShellScript "hindsight-postgres-entrypoint" ''
    set -eu

    : "''${PGDATA:=/var/lib/postgresql/data}"
    : "''${POSTGRES_USER:=hindsight}"
    : "''${POSTGRES_PASSWORD:=hindsight}"
    : "''${POSTGRES_DB:=hindsight}"

    if [ ! -s "$PGDATA/PG_VERSION" ]; then
      mkdir -p "$PGDATA"
      initdb --username="$POSTGRES_USER" \
             --pwfile=<(printf '%s\n' "$POSTGRES_PASSWORD") \
             --encoding=UTF8 \
             --locale=C.UTF-8 \
             "$PGDATA"
      printf "listen_addresses = '*'\n" >> "$PGDATA/postgresql.conf"
      printf "host all all 0.0.0.0/0 scram-sha-256\n" >> "$PGDATA/pg_hba.conf"

      postgres -D "$PGDATA" &
      postgres_pid=$!
      trap 'kill "$postgres_pid"' EXIT

      until pg_isready -h 127.0.0.1 -U "$POSTGRES_USER"; do
        sleep 1
      done

      psql -v ON_ERROR_STOP=1 --username="$POSTGRES_USER" --dbname=postgres \
        --command="CREATE DATABASE \"$POSTGRES_DB\";"

      psql -v ON_ERROR_STOP=1 --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" \
        --command='CREATE EXTENSION IF NOT EXISTS vector CASCADE; CREATE EXTENSION IF NOT EXISTS pgroonga CASCADE;'

      kill "$postgres_pid"
      wait "$postgres_pid" || true
      trap - EXIT
    fi

    exec postgres -D "$PGDATA"
  '';

  hindsightPostgresImage = pkgs.dockerTools.buildImage {
    name = "hindsight-postgres";
    tag = "17";
    copyToRoot = pkgs.buildEnv {
      name = "hindsight-postgres-root";
      paths = [ postgresWithExts pkgs.bash pkgs.coreutils ];
      pathsToLink = [ "/bin" "/lib" "/share" ];
    };
    runAsRoot = ''
      ${pkgs.dockerTools.shadowSetup}
      groupadd -g 999 -r postgres
      useradd -u 999 -r -g postgres -d /var/lib/postgresql postgres
      mkdir -p /var/lib/postgresql/data /run/postgresql
      chown -R postgres:postgres /var/lib/postgresql /run/postgresql
    '';
    config = {
      Entrypoint = [ "${hindsightPostgresEntrypoint}" ];
      User = "postgres";
    };
  };
in
{
  sops.secrets = {
    "hindsight/opencode" = { };
    "hindsight/openrouter" = { };
    "hindsight/jina" = { };
  };

  sops.templates."hindsight-env" = {
    content = ''
      HINDSIGHT_API_LLM_API_KEY=${config.sops.placeholder."hindsight/opencode"}
      HINDSIGHT_API_EMBEDDINGS_LITELLM_SDK_API_KEY=${config.sops.placeholder."hindsight/jina"}
      HINDSIGHT_API_RERANKER_LITELLM_SDK_API_KEY=${config.sops.placeholder."hindsight/jina"}
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/hindsight/postgres 0700 999 999 - -"
    "h /var/lib/hindsight/postgres - - - - +C"
  ];

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) containers networks;
  in {
    networks.hindsight = {
      networkConfig.driver = "bridge";
    };

    containers = {
      hindsight-postgres = {
        containerConfig = {
          image = "docker-archive:${hindsightPostgresImage}";
          networks = [ networks.hindsight.ref ];
          volumes = [ "/var/lib/hindsight/postgres:/var/lib/postgresql/data" ];
          environments = {
            POSTGRES_USER = "hindsight";
            POSTGRES_PASSWORD = "hindsight";
            POSTGRES_DB = "hindsight";
          };
          logDriver = "json-file";
          logOptions = [ "max-size=10m" "max-file=3" "compress=true" ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "5";
        };
      };

      hindsight = {
        containerConfig = {
          image = "ghcr.io/vectorize-io/hindsight:latest-slim";
          networks = [ networks.hindsight.ref ];
          publishPorts = [
            "8888:8888"
            "9999:9999"
          ];
          environmentFiles = [
            config.sops.templates."hindsight-env".path
          ];
          environments = {
            # Hindsight's `opencode-go` provider uses /chat/completions,
            # but Muse Spark on OpenCode Go only supports /responses
            HINDSIGHT_API_LLM_PROVIDER = "openai-responses";
            HINDSIGHT_API_LLM_BASE_URL = "https://opencode.ai/zen/go/v1";
            HINDSIGHT_API_LLM_MODEL = "muse-spark-1.3-contributor";

            HINDSIGHT_API_EMBEDDINGS_PROVIDER = "litellm-sdk";
            HINDSIGHT_API_EMBEDDINGS_LITELLM_SDK_MODEL = "jina_ai/jina-embeddings-v5-omni-small";
            # Jina doesn't support default `float`
            HINDSIGHT_API_EMBEDDINGS_LITELLM_SDK_ENCODING_FORMAT = "";

            HINDSIGHT_API_RERANKER_PROVIDER = "litellm-sdk";
            HINDSIGHT_API_RERANKER_LITELLM_SDK_MODEL = "jina_ai/jina-reranker-v3.5";

            HINDSIGHT_API_DATABASE_URL = "postgresql://hindsight:hindsight@hindsight-postgres:5432/hindsight";
            HINDSIGHT_API_WORKER_ID = "hindsight";

            HINDSIGHT_API_VECTOR_EXTENSION = "pgvector";
            HINDSIGHT_API_TEXT_SEARCH_EXTENSION = "pgroonga";
          };
          logDriver = "json-file";
          logOptions = [ "max-size=10m" "max-file=3" "compress=true" ];
        };
        unitConfig = {
          Requires = [ containers.hindsight-postgres.ref ];
          After = [ containers.hindsight-postgres.ref ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };
    };
  };
}

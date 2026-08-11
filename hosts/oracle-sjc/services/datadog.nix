{ config, ... }:

{
  sops.secrets = {
    "datadog" = { };
  };

  sops.templates."datadog-env" = {
    content = ''
      DD_API_KEY=${config.sops.placeholder."datadog"}
    '';
  };

  systemd.sockets.podman.enable = true;

  virtualisation.quadlet = {
    containers = {
      dd-agent = {
        containerConfig = {
          image = "registry.datadoghq.com/agent:7";
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock:ro"
            "/proc/:/host/proc/:ro"
            "/sys/fs/cgroup/:/host/sys/fs/cgroup:ro"
          ];
          environmentFiles = [
            config.sops.templates."datadog-env".path
          ];
          environments = {
            DD_SITE = "datadoghq.com";
            DD_DOGSTATSD_NON_LOCAL_TRAFFIC = "true";
          };
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };
    };
  };
}

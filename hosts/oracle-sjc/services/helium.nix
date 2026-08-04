{ config, ... }:

{
  systemd.tmpfiles.rules = [
    "d /var/lib/helium 0700 999 999 - -"
  ];

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) containers;
  in {
    containers = {
      helium = {
        containerConfig = {
          image = "lscr.io/linuxserver/helium:latest";
          volumes = [ "/var/lib/helium:/config" ];
          publishPorts = [
            "3000:3000" # HTTP
            "3001:3001" # HTTPS
            "9222:9223" # socat -> CDP
          ];
          environments = {
            PUID = "999";
            PGID = "999";
            HELIUM_CLI = builtins.concatStringsSep " " [
              "--proxy-server=socks5://100.89.204.14:7890" # dmit-lax
              "--remote-debugging-port=9222"
            ];
          };
          shmSize = "4g";
          logDriver = "json-file";
          logOptions = [ "max-size=10m" "max-file=3" "compress=true" ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };

      helium-cdp-proxy = {
        containerConfig = {
          image = "docker.io/alpine/socat";
          networks = [ "container:helium" ];
          exec = [ "tcp-listen:9223,fork,reuseaddr" "tcp:127.0.0.1:9222" ];
        };
        unitConfig = {
          Requires = [ containers.helium.ref ];
          After = [ containers.helium.ref ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "5";
        };
      };
    };
  };
}

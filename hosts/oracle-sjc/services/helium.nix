{ ... }:

# https://github.com/linuxserver/docker-helium/blob/34024391e7ee91b9d841f623246838d953fe852f/README.md#usage
let
  stateDirectory = "/var/lib/helium";
in
{
  systemd.tmpfiles.rules = [
    "d ${stateDirectory} 0755 999 999 - -"
    "d ${stateDirectory}/Downloads 0777 999 999 - -"
  ];

  environment.persistence."/persist" = {
    directories = [ stateDirectory ];
  };

  virtualisation.quadlet = {
    containers = {
      helium = {
        containerConfig = {
          image = "lscr.io/linuxserver/helium:latest";
          networks = [ "host" ];
          volumes = [ "${stateDirectory}:/config" ];
          environments = {
            PUID = "999";
            PGID = "999";
            HELIUM_CLI = builtins.concatStringsSep " " [
              "--proxy-server=socks5://100.89.204.14:7890" # dmit-lax
              "--proxy-bypass-list=100.64.0.0/10;*.ts.net;<local>"
              "--remote-debugging-port=9222"
              "--remote-allow-origins=*"
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
    };
  };
}

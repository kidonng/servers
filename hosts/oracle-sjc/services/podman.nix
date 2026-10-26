{ inputs, ... }:

{
  imports = [ inputs.quadlet-nix.nixosModules.quadlet ];

  systemd.services.podman.environment = {
    LOGGING = "--log-level=warn";
  };

  environment.persistence."/persist" = {
    directories = [ "/var/lib/containers" ];
  };
}

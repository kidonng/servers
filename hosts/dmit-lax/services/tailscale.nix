{ config, ... }:

{
  sops.secrets = {
    "tailscale" = {
      reloadUnits = [ config.systemd.services.tailscaled.name ];
    };
  };

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale.path;
  };
}

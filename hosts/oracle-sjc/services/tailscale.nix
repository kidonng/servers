{ config, ... }:

{
  sops.secrets = {
    "tailscale" = { };
  };

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale.path;
  };

  networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
}

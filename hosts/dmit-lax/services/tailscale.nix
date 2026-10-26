{ config, pkgs, ... }:

{
  sops.secrets = {
    "tailscale" = { };
  };

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale.path;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--advertise-exit-node"
    ];
  };

  networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];

  systemd.services.tailscale-udp-gro = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -K enp6s18 rx-udp-gro-forwarding on rx-gro-list off";
    };
  };
}

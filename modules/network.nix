{ lib, ... }:

{
  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = lib.mkDefault "eth* ens* enp*";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
    };
  };

  boot = {
    kernelModules = [ "tcp_bbr" ];
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };
}

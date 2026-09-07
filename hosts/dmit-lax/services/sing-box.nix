{ config, ... }:

# https://sing-box.sagernet.org/manual/proxy-protocol/shadowsocks/
# https://sing-box.sagernet.org/manual/proxy-protocol/hysteria2/
let
  shadowsocksPort = 10724;
  hysteria2Port = 20724;
  sopsConfig = {
    reloadUnits = [ config.systemd.services.sing-box.name ];
  };
in
{
  sops.secrets = {
    "sing-box/shadowsocks/password" = sopsConfig;
    "sing-box/shadowsocks/users/kid" = sopsConfig;
    "sing-box/shadowsocks/users/bro" = sopsConfig;
    "sing-box/shadowsocks/users/hxq" = sopsConfig;
    "sing-box/shadowsocks/users/sov" = sopsConfig;
    "sing-box/shadowsocks/users/yao" = sopsConfig;
    "sing-box/hysteria2/users/kid" = sopsConfig;
    "sing-box/acme/cloudflare" = sopsConfig;
  };

  services.sing-box = {
    enable = true;
    settings = {
      log.level = "error";
      inbounds = [
        {
          type = "mixed";
          listen = "::";
          listen_port = 7890;
        }
        {
          type = "shadowsocks";
          listen = "::";
          listen_port = shadowsocksPort;
          method = "2022-blake3-aes-128-gcm";
          password._secret = config.sops.secrets."sing-box/shadowsocks/password".path;
          users = [
            {
              name = "kid";
              password._secret = config.sops.secrets."sing-box/shadowsocks/users/kid".path;
            }
            {
              name = "bro";
              password._secret = config.sops.secrets."sing-box/shadowsocks/users/bro".path;
            }
            {
              name = "hxq";
              password._secret = config.sops.secrets."sing-box/shadowsocks/users/hxq".path;
            }
            {
              name = "sov";
              password._secret = config.sops.secrets."sing-box/shadowsocks/users/sov".path;
            }
            {
              name = "yao";
              password._secret = config.sops.secrets."sing-box/shadowsocks/users/yao".path;
            }
          ];
          multiplex.enabled = true;
        }
        {
          type = "hysteria2";
          listen = "::";
          listen_port = hysteria2Port;
          users = [
            {
              name = "kid";
              password._secret = config.sops.secrets."sing-box/hysteria2/users/kid".path;
            }
          ];
          tls = {
            enabled = true;
            server_name = "aria.xuann.wang";
            acme = {
              domain = "aria.xuann.wang";
              dns01_challenge = {
                provider = "cloudflare";
                api_token._secret = config.sops.secrets."sing-box/acme/cloudflare".path;
              };
            };
          };
        }
      ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ shadowsocksPort ];
    allowedUDPPorts = [ shadowsocksPort hysteria2Port ];
  };
}

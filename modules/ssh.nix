{ config, ... }:

{
  services.openssh = {
    enable = true;
    openFirewall = !config.services.tailscale.enable;
    hostKeys = [
      {
        type = "ed25519";
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
      }
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPMTyNclTKss6hWrzPeenAOEN+OoJ7zsipv0H3QegDOA Laptop"
  ];
}

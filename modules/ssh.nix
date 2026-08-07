{ ... }:

{
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        type = "ed25519";
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
      }
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPMTyNclTKss6hWrzPeenAOEN+OoJ7zsipv0H3QegDOA" # Laptop
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID65n4iyuITzbmAWaHQE7oulXtz8zHkMnkvqofsu0GLB" # Phone
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIp7adoHn+fAO0e/FwnZAotqCx1ci6ACA1fEUH31hV9f" # Tablet
  ];
}

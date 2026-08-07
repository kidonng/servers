# Servers

NixOS config for my servers.

## Adding host

```sh
# Scaffold
mkdir hosts/new-host
cp hosts/{existing-host,new-host}/default.nix
$EDITOR flake.nix

# Configure key & stub secrets
mkdir -p extra/persist/etc/ssh
ssh-keygen -t ed25519 -N "" -f extra/persist/etc/ssh/ssh_host_ed25519_key
ssh-to-age -i extra/persist/etc/ssh/ssh_host_ed25519_key.pub
$EDITOR .sops.yaml
sops hosts/new-host/secrets.yaml

# Deploy
# https://github.com/nix-community/nixos-anywhere
nix run github:nix-community/nixos-anywhere -- \
  --flake .#new-host \
  --target-host root@<host> \
  --generate-hardware-config hosts/new-host/hardware.nix \
  --extra-files extra
```

# Servers

NixOS config for my servers.

## Adding host

```sh
# Scaffold
mkdir hosts/new-host
cp hosts/{existing-host,new-host}/default.nix
$EDITOR flake.nix

# Configure key & stub secrets
age-keygen -o sops-key
$EDITOR .sops.yaml
sops hosts/new-host/secrets.yaml

# Deploy
mkdir -p extra/persist
cp sops-key extra/persist
# https://github.com/nix-community/nixos-anywhere
nix run github:nix-community/nixos-anywhere -- \
  --flake .#new-host \
  --target-host root@<host> \
  --generate-hardware-config hosts/new-host/hardware.nix \
  --extra-files extra
```

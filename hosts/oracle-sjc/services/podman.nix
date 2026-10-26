{ inputs, ... }:

{
  imports = [ inputs.quadlet-nix.nixosModules.quadlet ];

  environment.persistence."/persist" = {
    directories = [ "/var/lib/containers" ];
  };
}

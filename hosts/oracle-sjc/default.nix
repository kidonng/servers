{ inputs, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  specialArgs = { inherit inputs; };
  modules = [
    inputs.sops-nix.nixosModules.sops
    inputs.quadlet-nix.nixosModules.quadlet
    ../../modules/disk-uefi.nix
    ../../modules/impermanence.nix
    ../../modules/network.nix
    ../../modules/nix.nix
    ../../modules/ssh.nix
    ./hardware.nix
    ./services/datadog.nix
    ./services/firecrawl.nix
    ./services/helium.nix
    ./services/hermes-agent.nix
    ./services/hindsight.nix
    ./services/tailscale.nix
    {
      sops = {
        defaultSopsFile = ./secrets.yaml;
        age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
      };

      networking.hostName = "oracle-sjc";

      disko.devices.disk.vda.device = "/dev/sda";

      system.stateVersion = "26.11";
    }
  ];
}

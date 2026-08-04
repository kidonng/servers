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
    ./services/hermes-agent.nix
    ./services/firecrawl.nix
    ./services/hindsight.nix
    {
      sops = {
        defaultSopsFile = ./secrets.yaml;
        age.keyFile = "/persist/sops-key";
      };

      networking.hostName = "oracle-sjc";

      disko.devices.disk.vda.device = "/dev/sda";

      system.stateVersion = "26.11";
    }
  ];
}

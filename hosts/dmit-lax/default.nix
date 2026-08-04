{ inputs, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit inputs; };
  modules = [
    inputs.sops-nix.nixosModules.sops
    ../../modules/disk-bios.nix
    ../../modules/impermanence.nix
    ../../modules/network.nix
    ../../modules/nix.nix
    ../../modules/ssh.nix
    ./hardware.nix
    ./services/sing-box.nix
    ./services/tailscale.nix
    {
      sops = {
        defaultSopsFile = ./secrets.yaml;
        age.keyFile = "/var/lib/sops/key.txt";
      };

      networking.hostName = "dmit-lax";

      services.qemuGuest.enable = true;

      zramSwap = {
        enable = true;
        memoryPercent = 100;
      };

      system.stateVersion = "26.11";
    }
  ];
}

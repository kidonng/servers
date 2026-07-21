{ inputs, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  specialArgs = { inherit inputs; };
  modules = [
    inputs.determinate.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ../../modules/disk-uefi.nix
    ../../modules/impermanence.nix
    ../../modules/network.nix
    ../../modules/ssh.nix
    ./hardware.nix
    {
      sops = {
        defaultSopsFile = ./secrets.yaml;
        age.keyFile = "/var/lib/sops/key.txt";
      };

      networking.hostName = "oracle-sjc";

      disko.devices.disk.vda.device = "/dev/sda";

      system.stateVersion = "26.11";
    }
  ];
}

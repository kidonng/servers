{ inputs, lib, ... }:

{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices = {
    disk.vda = {
      type = "disk";
      device = lib.mkDefault "/dev/vda";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            type = "EF02";
            size = "1M";
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" "-L" "nixos-root" ];
              subvolumes = {
                "root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "boot" = {
                  mountpoint = "/boot";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "persist" = {
                  mountpoint = "/persist";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}

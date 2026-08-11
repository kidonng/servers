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
            type = "EF00";
            size = "1G";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" "-L" "nixos-root" ];
              subvolumes = {
                "root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd:1" "noatime" ];
                };
                "nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd:1" "noatime" ];
                };
                "persist" = {
                  mountpoint = "/persist";
                  mountOptions = [ "compress=zstd:1" "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
}

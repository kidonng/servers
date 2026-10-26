{ inputs, pkgs, ... }:

{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/log/journal"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  fileSystems."/persist".neededForBoot = true;

  boot.initrd.systemd.services.rollback = {
    requires = [ "initrd-root-device.target" ];
    after = [ "initrd-root-device.target" ];
    before = [ "sysroot.mount" ];
    wantedBy = [ "initrd.target" ];

    unitConfig.DefaultDependencies = "no";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [
      pkgs.btrfs-progs
      pkgs.coreutils
      pkgs.util-linux
    ];

    script = ''
      rootPart=/root_part
      rootSubvol="$rootPart/root"

      mkdir -p "$rootPart"
      mount -t btrfs /dev/disk/by-label/nixos-root "$rootPart"

      if [ -e "$rootSubvol" ]; then
          btrfs subvolume delete -R "$rootSubvol"
      fi
      btrfs subvolume create "$rootSubvol"

      umount "$rootPart"
    '';
  };
}

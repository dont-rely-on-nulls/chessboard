{ target }:
let
  # Device names differ by environment
  deviceOptions = {
    aws = "nvme0n1";
    mgc = "vda";
    vm = "vda";
  };
  device = deviceOptions.${target};

  # Only the VM needs an image size
  extraAttrs = if target == "vm" then { imageSize = "40G"; } else { };

  # Partition size parameters per target
  partitionOptions = {
    aws = {
      swap = "16G";
    };
    mgc = {
      swap = "16G";
    };
    vm = {
      swap = "4G";
    };
  };
  sizes = partitionOptions.${target};

  defaultMountOptions = [
    "defaults"
    "noatime"
  ];
in
{
  devices = {
    disk.main = extraAttrs // {
      device = "/dev/${device}";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02";
          };
          esp = {
            type = "EF00";
            size = "1G";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          swap = {
            name = "swap";
            size = sizes.swap;
            content.type = "swap";
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "root_vg";
            };
          };
        };
      };
    };

    lvm_vg = {
      root_vg = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "10%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = defaultMountOptions;
            };
          };

          nix = {
            size = "45%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
              mountOptions = defaultMountOptions;
            };
          };

          persist = {
            size = "45%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/persist";
              mountOptions = defaultMountOptions;
            };
          };
        };
      };
    };
  };
}

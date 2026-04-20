{
  aws = {
    name = "aws";
    device = "nvme0n1";
    swap = {
      size = "16G";
    };
  };

  mgc = {
    name = "magalu_cloud";
    device = "vda";
    swap = {
      size = "16G";
    };
  };

  vm = {
    name = "vm";
    device = "vda";
    swap = {
      size = "4G";
    };
  };
}

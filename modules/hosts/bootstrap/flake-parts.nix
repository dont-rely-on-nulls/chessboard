{ inputs, ... }:
let
  nixpkgsModules = "${inputs.nixpkgs}/nixos/modules";

  commonModules = [
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    inputs.self.modules.nixos.common
    inputs.self.modules.nixos.disk
    inputs.self.modules.nixos.persistence
    inputs.self.modules.nixos.ssh
    inputs.self.modules.nixos.users
    inputs.self.modules.nixos.bootstrap
  ];
in
{
  flake.nixosConfigurations = {
    # -------
    #   AWS
    # -------
    # sudo nixos-rebuild boot --flake .#bootstrap_aws
    bootstrap_aws = inputs.nixpkgs.lib.nixosSystem {
      modules = commonModules ++ [
        { modules.disko.target = "aws"; }
        "${nixpkgsModules}/virtualisation/amazon-image.nix"
      ];
    };

    # -------
    #   MGC
    # -------
    # sudo nixos-rebuild boot --flake .#bootstrap_mgc
    bootstrap_mgc = inputs.nixpkgs.lib.nixosSystem {
      modules = commonModules ++ [
        { modules.disko.target = "mgc"; }
        "${nixpkgsModules}/profiles/qemu-guest.nix"
      ];
    };

    # --------
    #   QEMU
    # --------
    # sudo nixos-rebuild boot --flake .#bootstrap_vm
    bootstrap_vm = inputs.nixpkgs.lib.nixosSystem {
      modules = commonModules ++ [
        { modules.disko.target = "vm"; }
        "${nixpkgsModules}/profiles/qemu-guest.nix"
      ];
    };
  };
}

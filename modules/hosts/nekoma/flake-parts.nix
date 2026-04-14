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
    inputs.self.modules.nixos.nekoma
    inputs.self.modules.nixos.postgresql
    inputs.self.modules.nixos.lyceum
    inputs.self.modules.nixos.secrets
  ];
in
{
  flake.nixosConfigurations = {
    # -------
    #   AWS
    # -------
    # sudo nixos-rebuild boot --flake .#nekoma_aws
    nekoma_aws = inputs.nixpkgs.lib.nixosSystem {
      modules = commonModules ++ [
        { modules.disko.target = "aws"; }
        "${nixpkgsModules}/virtualisation/amazon-image.nix"
      ];
      specialArgs = { inherit (inputs) lyceum; };
    };

    # -------
    #   MGC
    # -------
    # sudo nixos-rebuild boot --flake .#nekoma_mgc
    nekoma_mgc = inputs.nixpkgs.lib.nixosSystem {
      modules = commonModules ++ [
        { modules.disko.target = "mgc"; }
        "${nixpkgsModules}/profiles/qemu-guest.nix"
      ];
      specialArgs = { inherit (inputs) lyceum; };
    };

    # --------
    #   QEMU
    # --------
    # sudo nixos-rebuild boot --flake .#nekoma_vm
    nekoma_vm = inputs.nixpkgs.lib.nixosSystem {
      modules = commonModules ++ [
        { modules.disko.target = "vm"; }
        "${nixpkgsModules}/profiles/qemu-guest.nix"
      ];
      specialArgs = { inherit (inputs) lyceum; };
    };
  };
}

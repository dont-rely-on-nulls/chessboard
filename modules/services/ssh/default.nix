{ ... }:
{
  flake.modules.nixos.ssh = import ./_nixos.nix;
}

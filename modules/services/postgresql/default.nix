{ ... }:
{
  flake.modules.nixos.postgresql = import ./_nixos.nix;
}

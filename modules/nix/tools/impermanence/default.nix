{ ... }:
{
  flake.modules.nixos.persistence = import ./_nixos.nix;
}

{ ... }:
{
  flake.modules.nixos.bootstrap = import ./_nixos.nix;
}

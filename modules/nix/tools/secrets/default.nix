{ ... }:
{
  flake.modules.nixos.secrets = import ./_nixos.nix;
}

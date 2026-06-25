{ ... }:
{
  # Stage 2: full production configuration for the nekoma host
  flake.modules.nixos.nekoma = import ./_nixos.nix;
}

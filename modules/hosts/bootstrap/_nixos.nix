# Stage 1: Minimal bootstrap used by nixos-anywhere for the initial install
{ lib, ... }:
{
  modules.common = {
    enable = true;
  };

  modules.disko = {
    enable = true;
    profile = "ext4";
    # target is set per nixosConfiguration in flake-parts.nix
  };

  modules.impermanence = {
    enable = true;
  };

  modules.ssh = {
    enable = true;
  };

  # This is required by ZFS
  # https://search.nixos.org/options?channel=unstable&show=networking.hostId&query=networking.hostId
  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "41d2315f";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

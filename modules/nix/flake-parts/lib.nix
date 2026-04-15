{ inputs, lib, ... }:
{
  # Enable the flake.modules namespace so flake.modules.nixos.* can be merged
  # across all auto-discovered feature modules.
  imports = [ inputs.flake-parts.flakeModules.modules ];

  # Convenience helpers stored in flake.lib for use by host flake-parts modules
  options.flake.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  config.flake.lib = {
    # Build a NixOS configuration from a flake.modules.nixos.<name> entry
    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = lib.mkDefault system; }
        ];
      };
    };
  };
}

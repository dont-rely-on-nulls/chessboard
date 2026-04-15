{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.common;
  disko_module = config.modules.disko;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.modules.common = {
    enable = mkEnableOption "Common settings shared by all machines";
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      boot = {
        kernelPackages = pkgs.linuxPackages_latest;
        tmp.cleanOnBoot = true;
      };

      zramSwap.enable = true;

      documentation.enable = false;

      environment.systemPackages = with pkgs; [
        bash
        git
        pciutils
      ];

      networking.networkmanager.enable = true;

      # Nix settings
      nixpkgs = {
        config = {
          allowUnfree = true;
        };
      };

      nix = {
        package = pkgs.nixVersions.stable;
        settings.trusted-users = [
          "root"
          "@wheel"
        ];
        extraOptions = ''
          experimental-features = nix-command flakes
        '';
        # Clean up /nix/store/ after 2 weeks
        gc = {
          automatic = true;
          dates = "weekly UTC";
          options = "--delete-older-than 14d";
        };
        optimise.automatic = true;
      };
      security.sudo.wheelNeedsPassword = false;

      # Extra stuff
      # programs.zsh.enable = true;
      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
      };

      # Don't change this!
      system.stateVersion = "25.11";
    })

    (mkIf (disko_module.enable && disko_module.target == "vm") {
      # Enable QEMU guest agent
      services.qemuGuest.enable = true;

      # Disable automatic filesystem creation from nixos-generators
      system.build.qemuFormatOverride = true;

      # Autologin to root
      services.getty.autologinUser = "root";
      security.sudo.wheelNeedsPassword = false;

      # Redirect port 22 to 2222 on host
      virtualisation.vmVariant = {
        virtualisation.forwardPorts = [
          {
            from = "host";
            host.port = 2222;
            guest.port = 22;
          }
        ];
      };
    })
  ]);
}

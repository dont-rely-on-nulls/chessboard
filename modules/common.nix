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
        kernel.sysctl = {
          # Increase PID limit (for many connections)
          "kernel.pid_max" = 65536;
          "kernel.sched_migration_cost_ns" = 5000000;
          "kernel.sched_autogroup_enabled" = 0;

          # 1GB
          "kernel.shmmax" = 4 * 1024 * 1024 * 1024;
          "kernel.shmall" = 1024 * 1024;

          # Filesystem Settings
          "fs.aio-max-nr" = 1048576;
          "fs.file-max" = 65536;

          # Network settings
          "net.core.somaxconn" = 2048;
          "net.core.netdev_max_backlog" = 5000;
          "net.core.rmem_default" = 4 * 16 * 4096;
          "net.core.wmem_default" = 4 * 16 * 4096;
          "net.core.rmem_max" = 134217728;
          "net.core.wmem_max" = 134217728;
          "net.ipv4.tcp_rmem" = "4096 87380 134217728";
          "net.ipv4.tcp_wmem" = "4096 65536 134217728";
          "net.ipv4.tcp_max_syn_backlog" = 2048;
          "net.ipv4.tcp_keepalive_time" = 600;
          "net.ipv4.tcp_keepalive_probes" = 3;
          "net.ipv4.tcp_keepalive_intvl" = 30;

          # Memory Settings
          "vm.swappiness" = 1;
          "vm.dirty_ratio" = 10;
          "vm.dirty_background_ratio" = 3;
          "vm.dirty_expire_centisecs" = 500;
          "vm.dirty_writeback_centisecs" = 100;
          "vm.overcommit_memory" = 2;
          "vm.overcommit_ratio" = 80;
          "vm.zone_reclaim_mode" = 0;
        };
      };

      zramSwap.enable = true;

      documentation.enable = false;

      environment.systemPackages = with pkgs; [
        bash
        htop
      ];

      networking.networkmanager.enable = true;

      services.sysstat.enable = true;

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

{
  lib,
  config,
  pkgs,
  ...
}@args:

let
  cfg = config.modules.lyceum;
  postgresql_module = config.modules.postgresql;
  impermanence_module = config.modules.impermanence;

  # Get the lyceum server package from the flake input
  lyceum_server =
    if args ? lyceum then
      args.lyceum.packages.${pkgs.system}.server
    else
      throw "The 'lyceum' flake input must be passed via specialArgs to use the lyceum module";

  lyceum_work_dir =
    if impermanence_module.enable then
      "${impermanence_module.directory}/home/${cfg.user}"
    else
      "/home/${cfg.user}";

  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.modules.lyceum = {
    enable = mkEnableOption "Enable Lyceum's backend";

    user = mkOption {
      type = lib.types.str;
      default = "deploy";
    };

    epmd_port = mkOption {
      type = lib.types.port;
      default = 4369;
      description = "Erlang Port Mapper Daemon port";
    };

    port_range = mkOption {
      type = lib.types.listOf lib.types.port;
      default = pkgs.lib.range 9100 9155;
      description = "Default port interval that Erlang apps need as well";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      environment.systemPackages = [
        lyceum_server
      ];

      networking = {
        # I don't like it, but we need to fix the game's server
        # before disabling this.
        # https://github.com/Dr-Nekoma/lyceum/issues/66
        firewall = {
          allowedTCPPorts = [
            cfg.epmd_port
          ]
          ++ cfg.port_range;
          allowedUDPPorts = [
            cfg.epmd_port
          ];
        };
      };

      # Systemd services
      systemd.services.lyceum = {
        description = "Lyceum Game Server";

        # Ensure dependencies and outputs are met
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "postgresql-lyceum-setup.service"
          "postgresql.service"
          "run-agenix.d.mount"
        ];
        requires = [
          "postgresql-lyceum-setup.service"
          "postgresql.service"
          "run-agenix.d.mount"
        ];
        # Still unsure wether to go with PartsOf or BindsTo
        # https://stackoverflow.com/a/47216959/4614840
        # https://unix.stackexchange.com/a/327006/117072
        # partOf = [
        #   "postgresql.service"
        # ];

        # To make sure the packages in the service's $PATH
        path = with pkgs; [
          coreutils
          gnugrep
          gawk
          liburing
          openssl
        ];

        serviceConfig = {
          Type = "exec";
          User = cfg.user;
          Group = "users";
          ExecStartPre = pkgs.writeShellScript "init.sh" ''
            # Wait for PostgreSQL to be fully ready
            until ${postgresql_module.package}/bin/pg_isready -q; do
              sleep 1
            done
          '';
          ExecStart = "${lyceum_server}/bin/lyceum foreground";
          Environment = [
            "ERL_DIST_PORT_RANGE_MIN=9100"
            "ERL_DIST_PORT_RANGE_MAX=9155"
            "ERL_EPMD_PORT=${toString cfg.epmd_port}"
            # Enable verbose Erlang distribution logging
            "ERL_FLAGS=-kernel inet_dist_listen_min 9100 inet_dist_listen_max 9155"
          ];

          # For foreground mode, systemd handles stopping via signals
          KillSignal = "SIGTERM";
          TimeoutStopSec = "30s";
          # Sometimes we run in some shitty cloud vms, so setting a
          # bigger timeout.
          TimeoutStartSec = "5min";

          # Restart configuration
          Restart = "on-failure";
          RestartSec = "10s";
          KillMode = "process";

          # Networking
          # Add these to ensure network access
          IPAddressDeny = "";
          IPAddressAllow = "any";
          PrivateNetwork = false;
          # RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];

          # Security hardening
          # NoNewPrivileges = true;

          # Filesystem hardening
          # ProtectSystem = "strict";
          # ProtectHome = "tmpfs";
          # PrivateTmp = true;
          # PrivateDevices = true;
          # ProtectKernelTunables = true;
          # ProtectKernelModules = true;
          # ProtectControlGroups = true;

          # Allow writing to runtime directory
          RuntimeDirectory = "lyceum";
          RuntimeDirectoryMode = "0755";

          # Logs
          StandardOutput = "journal";
          StandardError = "journal";
          SyslogIdentifier = "lyceum";

          # Resource limits
          # https://www.man7.org/linux/man-pages/man5/systemd.resource-control.5.html
          # Memory usage upper & lower bounds
          MemoryMax = "40%";
          MemoryHigh = "25%";
          MemoryLow = "10%";
          MemorySwapMax = "20%";

          LimitNOFILE = "65536";
          LimitNPROC = "4096";

          # Working directory
          WorkingDirectory = "${lyceum_work_dir}/Apps";
        };

        # Restart on failure with backoff
        unitConfig = {
          StartLimitBurst = 5;
          StartLimitIntervalSec = 60;
        };
      };
    })
  ]);
}

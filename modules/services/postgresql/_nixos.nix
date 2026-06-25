{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.postgresql;
  pg = pkgs.postgresql_18;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.modules.postgresql = {
    enable = mkEnableOption "Enable/Disable custom PostgreSQL options";

    package = mkOption {
      default = pg;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      environment.systemPackages = with pkgs; [
        barman
        liburing
      ];

      services.postgresql = {
        enable = true;
        package = pg;
        ensureDatabases = [
          "lyceum"
        ];
        ensureUsers = [
          {
            name = "admin";
            ensureClauses = {
              login = true;
              superuser = true;
              createrole = true;
            };
          }

          {
            name = "lyceum";
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              createrole = true;
            };
          }

          {
            name = "lyceum_auth";
            ensureClauses = {
              login = true;
            };
          }

          {
            name = "application";
            ensureClauses = {
              login = true;
            };
          }

          {
            name = "migrations";
            ensureClauses = {
              login = true;
              superuser = true;
              createrole = true;
            };
          }

          {
            name = "mnesia";
            ensureClauses = {
              login = true;
            };
          }
        ];
        settings = {
          shared_preload_libraries = "pg_stat_statements";
          wal_level = "logical";
          # pg_stat_statements config, nested attr sets need to be
          # converted to strings, otherwise postgresql.conf fails
          # to be generated.
          compute_query_id = "on";
          "pg_stat_statements.max" = 10000;
          "pg_stat_statements.track" = "all";
          # All these settings bellow come from here
          # https://pgtune.leopard.in.ua/
          shared_buffers = "1GB";
          effective_cache_size = "3GB";
          maintenance_work_mem = "256MB";
          min_wal_size = "2GB";
          max_wal_size = "8GB";
          wal_buffers = "16MB";
          random_page_cost = "1.1";
          # Async/IO Setup
          io_method = "io_uring";
          # Increase work memory for large operations
          work_mem = "16MB";
          # Enable huge pages if available
          huge_pages = "try";
          # Adjust I/O concurrency settings
          effective_io_concurrency = 32;
          maintenance_io_concurrency = 32;
        };
        extensions = with pg.pkgs; [
          omnigres
          periods
          repmgr
        ];
        initialScript = pkgs.writeText "init-sql-script" ''
          CREATE EXTENSION pg_stat_statements;
        '';
      };

      services.pgbouncer = {
        enable = true;

        settings = {

          databases = {
            lyceum = "host=localhost port=5432 dbname=lyceum user=lyceum";
          };

          pgbouncer = {
            default_pool_size = 25;
            listen_addr = "*";
            listen_port = 6432;
            max_client_conn = 300;
            max_db_connections = 20;
            min_pool_size = 5;
            pool_mode = "transaction";
            reserve_pool_size = 5;
          };
        };
      };

      # Make pgbouncer wait for postgresql to be fully configured
      systemd.services.pgbouncer = {
        after = [
          "postgresql-lyceum-setup.service"
          "postgresql.service"
          "postgresql-setup.service"
        ];
        requires = [
          "postgresql-lyceum-setup.service"
          "postgresql.service"
          "postgresql-setup.service"
        ];
        # Add a small delay to ensure pg's postStart has completed
        serviceConfig = {
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        };
      };

      # haproxy
      #services.haproxy = {
      #  enable = true;
      #};

      services.keepalived = {
        enable = true;
      };
    })
  ]);
}

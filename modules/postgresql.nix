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
          # Monitoring & Statistics
          shared_preload_libraries = "pg_stat_statements";
          compute_query_id = "on";
          "pg_stat_statements.max" = 10000;
          "pg_stat_statements.track" = "all";
          # Most of these settings bellow come from here
          # https://pgtune.leopard.in.ua/
          # Memory Settings
          shared_buffers = "4GB";
          effective_cache_size = "12GB";
          maintenance_work_mem = "1GB";
          autovacuum_work_mem = "512MB";
          work_mem = "16MB";
          # WAL Settings
          wal_level = "logical";
          min_wal_size = "1GB";
          max_wal_size = "4GB";
          wal_buffers = "32MB";
          wal_compression = "lz4";
          # Query Planner Settings
          random_page_cost = "1.1";
          # Async/IO Setup
          io_method = "io_uring";
          io_combine_limit = "128kB";
          # Enable huge pages if available
          huge_pages = "try";
          # Adjust I/O concurrency settings
          effective_io_concurrency = 64;
          maintenance_io_concurrency = 32;
          max_worker_processes = 4;
          max_parallel_workers_per_gather = 2;
          max_parallel_workers = 4;
          max_parallel_maintenance_workers = 2;
          # Vacuum Settings
          autovacuum = "on";
          autovacuum_max_workers = 3;
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

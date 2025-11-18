{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.secrets;
  disko_module = config.modules.disko;
  impermanence_module = config.modules.impermanence;
  lyceum_module = config.modules.lyceum;
  postgresql_module = config.modules.postgresql;

  default_prefix = if impermanence_module.enable then impermanence_module.directory else "";
  lyceum_work_dir =
    if impermanence_module.enable then
      "${impermanence_module.directory}/home/${lyceum_module.user}"
    else
      "/home/${lyceum_module.user}";

  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.modules.secrets = {
    enable = mkEnableOption "Enable/Disable Agenix Secrets";

    paths = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      age = {
        # Private key of the SSH key pair. This is the other pair of what was supplied
        # in `secrets.nix`.
        #
        # This tells `agenix` where to look for the private key.
        identityPaths = [
          "${default_prefix}/var/lib/agenix/id_ed25519"
        ]
        ++ cfg.paths;
      };
    })

    # Lyceum
    (mkIf lyceum_module.enable {
      age = {
        secrets = {
          lyceum_application_env = {
            file = ../secrets/lyceum_application_env.age;
            owner = lyceum_module.user;
            group = "users";
            mode = "440";
          };
        };
      };

      # Make sure Lyceum's systemd service has the right envars
      systemd.services.lyceum = {
        serviceConfig = {
          EnvironmentFile = config.age.secrets.lyceum_application_env.path;
        };
      };
    })

    # PostgreSQL
    (mkIf (postgresql_module.enable) {
      age = {
        secrets = {
          pg_bouncer_auth_file = {
            file = ../secrets/pg_bouncer_auth_file.age;
            owner = config.systemd.services.pgbouncer.serviceConfig.User;
            group = config.systemd.services.pgbouncer.serviceConfig.Group;
            mode = "440";
          };

          pg_user_lyceum = {
            file = ../secrets/pg_user_lyceum.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "440";
          };

          pg_user_lyceum_application = {
            file = ../secrets/pg_user_lyceum_application.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "440";
          };

          pg_user_lyceum_auth = {
            file = ../secrets/pg_user_lyceum_auth.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "440";
          };

          pg_user_lyceum_mnesia = {
            file = ../secrets/pg_user_lyceum_mnesia.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "440";
          };

          pg_user_migrations = {
            file = ../secrets/pg_user_migrations.age;
            owner = config.systemd.services.postgresql.serviceConfig.User;
            group = config.systemd.services.postgresql.serviceConfig.Group;
            mode = "440";
          };
        };
      };

      # Add passswords after pg starts
      # https://discourse.nixos.org/t/assign-password-to-postgres-user-declaratively/9726/3
      # https://discourse.nixos.org/t/set-password-for-a-postgresql-user-from-a-file-agenix/41377/6
      systemd.services."postgresql-lyceum-setup" = {
        requiredBy = [
          "lyceum.service"
          "pgbouncer.service"
        ];
        requires = [
          "network.target"
          "postgresql.service"
          "postgresql-setup.service"
          "run-agenix.d.mount"
        ];
        after = [
          "network.target"
          "postgresql.service"
          "postgresql-setup.service"
          "run-agenix.d.mount"
        ];
        path = with pkgs; [
          coreutils
          postgresql_module.package
          replace-secret
        ];
        serviceConfig = {
          Type = "oneshot";
          User = "postgres";
          Group = "postgres";
          Restart = "on-failure";
          RemainAfterExit = true;
          RuntimeDirectory = "postgresql-lyceum";
          RuntimeDirectoryMode = "700";
        };
        script = ''
          # set bash options for early fail and error output         
          set -o errexit -o pipefail -o nounset -o errtrace
          shopt -s inherit_errexit                                                                                                                                 

          # Wait for PostgreSQL to be fully ready
          until ${postgresql_module.package}/bin/pg_isready -q; do
            sleep 1
          done

          # and check if the main role is there as well
          until $(psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='lyceum'" | grep -qi 1); do
            sleep 1
          done

          # Copy SQL template into temporary folder. The value of RuntimeDirectory is written into                 
          # environment variable RUNTIME_DIRECTORY by systemd.
          install --mode 600 ${../templates/pg-lyceum-init.tmpl.sql} ''$RUNTIME_DIRECTORY/init.sql

          # fill SQL template with passwords
          ${pkgs.replace-secret}/bin/replace-secret @PG_LYCEUM_USER@ ${config.age.secrets.pg_user_lyceum.path} ''$RUNTIME_DIRECTORY/init.sql
          ${pkgs.replace-secret}/bin/replace-secret @PG_LYCEUM_APPLICATION_USER@ ${config.age.secrets.pg_user_lyceum_application.path} ''$RUNTIME_DIRECTORY/init.sql
          ${pkgs.replace-secret}/bin/replace-secret @PG_LYCEUM_AUTH_USER@ ${config.age.secrets.pg_user_lyceum_auth.path} ''$RUNTIME_DIRECTORY/init.sql
          ${pkgs.replace-secret}/bin/replace-secret @PG_MIGRATION_USER@ ${config.age.secrets.pg_user_migrations.path} ''$RUNTIME_DIRECTORY/init.sql
          ${pkgs.replace-secret}/bin/replace-secret @PG_LYCEUM_MNESIA_USER@ ${config.age.secrets.pg_user_lyceum_mnesia.path} ''$RUNTIME_DIRECTORY/init.sql

          ${postgresql_module.package}/bin/psql --file "''$RUNTIME_DIRECTORY/init.sql"
        '';
      };

      services.pgbouncer.settings = {
        pgbouncer = {
          auth_file = config.age.secrets.pg_bouncer_auth_file.path;
        };
      };

    })
  ]);
}

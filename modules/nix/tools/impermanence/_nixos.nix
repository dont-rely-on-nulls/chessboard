# https://github.com/nix-community/impermanence#module-usage
{
  lib,
  config,
  ...
}:
let
  cfg = config.modules.impermanence;
  disko_module = config.modules.disko;
  defaultDirectories = {
    directories = [
      "Code"
      {
        directory = ".gnupg";
        mode = "0700";
      }
      {
        directory = ".ssh";
        mode = "0700";
      }
    ];
    files = [
      ".bash_history"
    ];
  };

  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    ;
in
{
  options.modules.impermanence = {
    enable = mkEnableOption "Enable the Impermanence module, for ephemeral state outside the Nix configuration";

    directory = mkOption {
      description = "The directory to use for the impermanence module.";
      default = "/persist";
      type = lib.types.str;
    };

  };

  config = mkIf cfg.enable (mkMerge [
    ({
      # Workaround for the following service failing with a bind mount for /etc/machine-id
      # see: https://github.com/nix-community/impermanence/issues/229
      # boot.initrd.systemd.suppressedUnits = [ "systemd-machine-id-commit.service" ];
      # systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
      environment.persistence."${cfg.directory}" = {
        hideMounts = true;
        directories = [
          "/etc/NetworkManager/system-connections"
          # This is the directory where we'll dump a private key
          # that will need to be used for "stage 2", when agenix
          # is enabled and requires a key to unlock the secrets.
          "/var/lib/agenix"
          "/var/lib/nixos"
          "/var/lib/postgresql"
          "/var/lib/tailscale"
          "/var/lib/systemd/coredump"
          "/var/log"
        ];
        files = [
          # machine-id is used by systemd for the journal, if you don't persist this
          # file you won't be able to easily use journalctl to look at journals for
          # previous boots.
          "/etc/machine-id"
        ];
        users = {
          bene = defaultDirectories;
          lemos = defaultDirectories;
          magueta = defaultDirectories;
          marinho = defaultDirectories;
          victor = defaultDirectories;

          deploy = {
            directories = [
              "Apps"
              {
                directory = ".gnupg";
                mode = "0700";
              }
              {
                directory = ".ssh";
                mode = "0700";
              }
            ];
            files = [
              ".zsh_history"
            ];
          };
        };
      };

      # Ensure impermanence's directory is needed as well
      fileSystems."${cfg.directory}".neededForBoot = true;
    })

    # Optional: additional VM-specific logic
    (mkIf (disko_module.enable && disko_module.target == "vm") {
      virtualisation.vmVariantWithDisko.virtualisation.fileSystems."${cfg.directory}".neededForBoot =
        true;
    })
  ]);
}

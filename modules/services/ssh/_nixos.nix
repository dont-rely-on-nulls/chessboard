{ lib, config, ... }:

let
  cfg = config.modules.ssh;
  impermanence_module = config.modules.impermanence;
  keys = import ../../users/_keys.nix;
  everyone = keys.allUsers keys.systems keys.users;
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
in
{
  options.modules.ssh = {
    enable = mkEnableOption "Enable/Disable custom SSH options";
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      services.openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = false;
          AllowUsers = [ "root" ] ++ everyone;
          X11Forwarding = false;
          # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
          PermitRootLogin = "prohibit-password";
        };
      };

      networking.firewall.allowedTCPPorts = [ 22 ];
    })

    # Optional behavior if impermanence is enabled
    (mkIf impermanence_module.enable {
      # https://discourse.nixos.org/t/how-to-define-actual-ssh-host-keys-not-generate-new/31775/8
      services.openssh = {
        hostKeys = [
          {
            type = "ed25519";
            path = "${impermanence_module.directory}/etc/ssh/ssh_host_ed25519_key";
          }
          {
            type = "rsa";
            bits = 4096;
            path = "${impermanence_module.directory}/etc/ssh/ssh_host_rsa_key";
          }
        ];
      };
    })
  ]);
}

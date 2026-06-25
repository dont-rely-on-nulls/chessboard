{
  lib,
  pkgs,
  specialArgs,
  ...
}:
let
  keys = import ./_keys.nix;
  allKeys = keys.allKeys keys.systems keys.users;
  everyone =
    (
      # Add terraform managed ssh key, if present
      lib.optional (specialArgs ? terraform_ssh_key) specialArgs.terraform_ssh_key
    )
    ++ allKeys;

  createDevUser = name: sshKeys: {
    isNormalUser = true;
    createHome = true;
    description = name;
    group = "users";
    extraGroups = [
      "wheel"
    ];
    openssh.authorizedKeys.keys = sshKeys;
  };
in
{
  users = {
    # Users are also immutable, can only be modified by Nix
    mutableUsers = false;

    # To make sure we can still log as root
    users.root.openssh.authorizedKeys.keys = everyone;

    # Other users
    users.bene = createDevUser "bene" keys.users.bene;
    users.deploy = createDevUser "deploy" everyone;
    users.lemos = createDevUser "lemos" keys.users.lemos;
    users.magueta = createDevUser "magueta" keys.users.magueta;
    users.marinho = createDevUser "marinho" keys.users.marinho;
    users.victor = createDevUser "victor" keys.users.victor;
  };
}

{ inputs, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];

  perSystem =
    { pkgs, system, ... }:
    let
      # Port Forwarding (HOST -> VM)
      # - SSH: 2222 -> 22
      # - EMPD: 4369
      # - Erlang Distribution Ports: 9100 (good enough for local testing)
      qemu_options = {
        net = "hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:4369-:4369,hostfwd=tcp:127.0.0.1:9100-:9100";
      };
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ../../../treefmt.nix;
    in
    {
      # This sets `pkgs` to a nixpkgs with allowUnfree option set.
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # nix build
      packages = {
        # ===============
        # Bootstrap Images
        # ===============
        # ISO
        # nix build .#iso
        iso = inputs.nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          modules = [
            inputs.agenix.nixosModules.default
            inputs.disko.nixosModules.disko
            inputs.impermanence.nixosModules.impermanence
            inputs.self.modules.nixos.common
            inputs.self.modules.nixos.disk
            inputs.self.modules.nixos.persistence
            inputs.self.modules.nixos.ssh
            inputs.self.modules.nixos.users
            inputs.self.modules.nixos.bootstrap
            { modules.disko.target = "vm"; }
            "${inputs.nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
          ];
          format = "iso";
        };

        # QEMU
        # nix build .#qemu
        qemu = inputs.nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          modules = [
            inputs.agenix.nixosModules.default
            inputs.disko.nixosModules.disko
            inputs.impermanence.nixosModules.impermanence
            inputs.self.modules.nixos.common
            inputs.self.modules.nixos.disk
            inputs.self.modules.nixos.persistence
            inputs.self.modules.nixos.ssh
            inputs.self.modules.nixos.users
            inputs.self.modules.nixos.bootstrap
            { modules.disko.target = "vm"; }
            "${inputs.nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
          ];
          format = "qcow";
        };
      };

      # nix run
      apps = {
        # https://github.com/nix-community/disko/blob/a5c4f2ab72e3d1ab43e3e65aa421c6f2bd2e12a1/docs/disko-images.md#test-the-image-inside-a-vm
        # nix run .#qemu
        qemu = {
          type = "app";

          program = "${pkgs.writeShellScript "run-vm.sh" ''
            set -e
            echo "Building VM with Disko..."
            ${pkgs.nix}/bin/nix build ".#nixosConfigurations.bootstrap_vm.config.system.build.vmWithDisko" "$@"

            export QEMU_KERNEL_PARAMS="console=ttyS0"
            export QEMU_NET_OPTS=${qemu_options.net}

            echo "Running VM..."
            ${pkgs.nix}/bin/nix run -L ".#nixosConfigurations.bootstrap_vm.config.system.build.vmWithDisko"
          ''}";
        };
      };

      # nix develop
      devShells = {
        # `nix develop .#ci`
        # reduce the number of packages to the bare minimum needed for CI
        ci = pkgs.mkShell {
          buildInputs = with pkgs; [
            just
          ];
        };

        # nix develop --impure
        default = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            (
              { pkgs, lib, ... }:
              {
                packages = with pkgs; [
                  age
                  inputs.agenix.packages.${system}.default
                  awscli2
                  bash
                  just
                ];

                scripts = {
                  # TOFU commands
                  ## Init
                  ia.exec = "just init aws";
                  im.exec = "just init mgc";
                  ## Plan
                  pa.exec = "just plan aws";
                  pm.exec = "just plan mgc";
                  ## Apply
                  aa.exec = "just apply aws";
                  am.exec = "just apply mgc";
                  ## Destroy
                  da.exec = "just destroy aws";
                  dm.exec = "just destroy mgc";
                  # VM commands
                  bq.exec = "just bq";
                  rq.exec = "just rq";
                };

                languages.opentofu = {
                  enable = true;
                };

                enterShell = ''
                  echo "Adding the Magalu CLI to \$PATH"
                  export PATH="$(pwd)/mg_cli:$PATH"
                  export QEMU_KERNEL_PARAMS="console=ttyS0"
                  export QEMU_NET_OPTS=${qemu_options.net}
                '';
              }
            )
          ];
        };
      };

      # nix fmt
      formatter = treefmtEval.config.build.wrapper;
    };
}

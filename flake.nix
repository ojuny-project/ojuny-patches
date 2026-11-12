{
  description = "Ojuny patch modules and catalogue checks";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
      source = nixpkgs.lib.cleanSource ./.;
    in
    {
      apps = forAllSystems (system: {
        ci = {
          type = "app";
          program = "${
            nixpkgs.legacyPackages.${system}.writeShellApplication {
              name = "ci";
              runtimeInputs = [ nixpkgs.legacyPackages.${system}.nix ];
              text = ''
                exec nix flake check "$@"
              '';
            }
          }/bin/ci";
        };
      });

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          annotations =
            pkgs.runCommand "check-patch-annotations"
              {
                nativeBuildInputs = [ pkgs.python3 ];
              }
              ''
                python3 ${source}/tests/annotations.py ${source}/modules/patches
                touch $out
              '';

          embedded-python =
            pkgs.runCommand "check-embedded-python"
              {
                nativeBuildInputs = [ pkgs.python3 ];
              }
              ''
                python3 ${source}/tests/embedded-python.py ${source}/modules/patches/patch-ojuny-agent.nix
                touch $out
              '';

          option-scan =
            pkgs.runCommand "check-option-scan"
              {
                nativeBuildInputs = [ pkgs.python3 ];
              }
              ''
                python3 ${source}/tests/option-scan.py ${source}/modules/patches/patch-ojuny-agent.nix
                touch $out
              '';

          nixshell-aliases =
            pkgs.runCommand "check-nixshell-aliases"
              {
                nativeBuildInputs = [ pkgs.python3 ];
              }
              ''
                python3 ${source}/tests/nixshell-aliases.py ${source}/modules/patches/patch-nixshell.nix
                touch $out
              '';

          catalogue =
            pkgs.runCommand "check-patch-catalogue"
              {
                nativeBuildInputs = [
                  pkgs.python3
                  pkgs.diffutils
                ];
              }
              ''
                cp -r ${source} work
                chmod -R u+w work
                cd work
                python3 scripts/gen-catalogue.py
                diff -u ${source}/CATALOGUE.md CATALOGUE.md
                touch $out
              '';

          default = pkgs.runCommand "check-patch-default" { } ''
            echo ${self.checks.${system}.annotations} >/dev/null
            echo ${self.checks.${system}.catalogue} >/dev/null
            echo ${self.checks.${system}.embedded-python} >/dev/null
            echo ${self.checks.${system}.option-scan} >/dev/null
            echo ${self.checks.${system}.nixshell-aliases} >/dev/null
            touch $out
          '';
        }
      );

      hydraJobs = forAllSystems (system: self.checks.${system});
    };
}

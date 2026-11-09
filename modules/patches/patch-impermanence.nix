/*
  @menu
  displayname = "Impermanence";
  icon = "drive-harddisk-symbolic";
  order = 90;
  description = "Ephemeral root with persisted paths";
  category = "Patches";
  systems = [ "all" ];
*/

# @inputs name = "impermanence"; url = "github:nix-community/impermanence";

{ self, inputs, ... }:
let
  hasImpermanence = inputs ? impermanence;
in
{
  flake.modules.nixos.patch-impermanence =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.ojuny.patch.impermanence;
    in
    {
      options.ojuny.patch.impermanence = {
        enable = lib.mkEnableOption "the impermanence patch";
        persistPath = lib.mkOption {
          type = lib.types.str;
          default = "/persist";
          description = "Mount point that contains the persisted paths.";
        };
      };

      imports = lib.optional hasImpermanence inputs.impermanence.nixosModules.impermanence;

      config = lib.mkIf (cfg.enable && hasImpermanence) {
        environment.persistence.${cfg.persistPath}.hideMounts = true;
      };

      assertions = lib.mkIf cfg.enable [
        {
          assertion = hasImpermanence;
          message = "ojuny.patch.impermanence requires inputs.impermanence. Add github:nix-community/impermanence to the host flake.";
        }
      ];
    };
}

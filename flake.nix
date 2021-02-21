{
  description = "Base16-template builder for nix.";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    {
      # Home Manager Module
      homeManagerModules.base16 = import ./base16.nix;

    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        updateScript = pkgs.writeShellScriptBin "update-base16" ''
          # should always be permitted to run to completion

          generate_sources () {
            out=$1
            curl "https://raw.githubusercontent.com/chriskempson/base16-$out-source/master/list.yaml"\
            | sed -nE "s~^([-_[:alnum:]]+): *(.*)~\1 \2~p"\
            | while read name src; do
                echo "{\"key\":\"$name\",\"value\":"
                nix-prefetch-git $src
                echo "}"
              done\
            | jq -s ".|del(.[].value.date)|from_entries"\
            > $out.json
          }

          generate_sources templates &
          generate_sources schemes &
          wait
        '';
      in {
        # Development environment.
        # Enter with `nix develop` and while inside, you can use `update-base16`
        # to update the sources lists.
        devShell = pkgs.mkShell {
          nativeBuildInputs = [
            updateScript
            pkgs.curl
            pkgs.nix-prefetch-git
            pkgs.gnused
            pkgs.jq
          ];
        };
      });
}

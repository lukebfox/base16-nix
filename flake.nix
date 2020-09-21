{
  description = "Base16-template builder for nix.";

  inputs.nixpkgs.url = "nixpkgs/release-20.03";

  outputs = inputs@{ self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in {

    # Home-Manager Module
    hmModules.base16 = import ./base16.nix;

    # Nix shell definition. Enter with 'nix develop'. Inside, can use
    # 'update-base16' to update the sources lists.
    devShell.x86_64-linux = let
      update = pkgs.writeShellScriptBin "update-base16" ''
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
    in pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        curl nix-prefetch-git gnused jq update
      ];
    };
  };
  
}

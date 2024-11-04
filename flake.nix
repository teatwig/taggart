{
  inputs = {
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (system:
    let
      elixir_version = "elixir_1_14";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          beam.packages.erlang."${elixir_version}"
          rebar3
          inotify-tools # mix_test_watch
        ];

        MIX_REBAR3 = "${pkgs.rebar3}/bin/rebar3";
      };
    }
  );
}

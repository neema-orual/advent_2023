{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    esp32 = {
      url = "github:Radiant-Industries/esp32";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , esp32
    ,
    }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      idf-rust = esp32.packages.x86_64-linux.esp32;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          idf-rust
          pkg-config
          libuv
          systemd
          openssl
          openssl.dev
        ];

        shellHook = ''
          export PATH="${idf-rust}/.rustup/toolchains/esp/bin:$PATH"
          export PATH="$HOME/.cargo/bin:$PATH"
          export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
          export RUSTUP_HOME="${idf-rust}/.rustup"
          source ./.export-esp.sh
        '';
      };
    };
}

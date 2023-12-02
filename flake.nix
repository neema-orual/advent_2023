{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  languages.c.enable = true;
                  env.name = "advent";
                  # https://devenv.sh/reference/options/
                  packages = [
                    pkgs.cc65
                    pkgs.c64-debugger
                    pkgs.minipro
                  ];

                  enterShell = ''
                    cc65 --version
                  '';

                  scripts.upload.exec = ''
                    ca65 -vvv --cpu 6502 -l build/listing.txt -o build/abn6507rom.o abn6507rom.s
                    ld65 -o build/abn6507rom.bin -C memmap.cfg "./build/abn6507rom.o" "./build/crom.o" "./build/userland.o"
                    serial="/dev/ttyUSB0" #linux
                    eval serial=$serial
                    cat -v < $serial & #Keep serial alive
                    pid=$! #Save for later
                    stty -f $serial $baudrate
                    echo -n $'\x01' > $serial #Send SOH to get 65uino ready to receive
                    sleep 0.1 #Wait for timeout
                    cat build/userland.bin > $serial
                    kill $pid #Terminate serial
                    wait $pid 2>/dev/null #silence!
                  '';

                  scripts.flash.exec = ''
                    ca65 -vvv --cpu 6502 -l build/listing.txt -o build/abn6507rom.o abn6507rom.s
                    ld65 -o build/abn6507rom.bin -C memmap.cfg "./build/abn6507rom.o" "./build/crom.o" "./build/userland.o"
                    minipro -s -p "SST39SF010A" -w build/abn6507rom.bin
                  '';
                }
              ];
            };
          });
    };
}

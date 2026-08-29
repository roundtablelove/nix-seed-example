{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-seed = {
      url = "github:roundtablelove/nix-seed";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {

    packages =
      inputs.nixpkgs.lib.genAttrs inputs.nixpkgs.lib.systems.flakeExposed
        (
          system:
          let
            pkgs = inputs.nixpkgs.legacyPackages.${system};
          in
          {
            default = pkgs.writeScriptBin "hello" ''
              ${pkgs.hello}/bin/hello -g "hello nix-seed"
            '';
            seed = inputs.nix-seed.lib.mkSeed {
              inherit pkgs;
              inherit (inputs) self;
            };
          }
        );

  };

}

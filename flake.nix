{
  inputs = {
    disko.url = "https://flakehub.com/f/nix-community/disko/1.13";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "https://flakehub.com/f/nix-community/impermanence/0.1";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
    sops-nix.url = "https://flakehub.com/f/Mic92/sops-nix/0.1";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = [
            pkgs.sops
          ];
        };
      });

      nixosConfigurations = {
        dmit-lax = import ./hosts/dmit-lax { inherit inputs; };
        oracle-sjc = import ./hosts/oracle-sjc { inherit inputs; };
      };
    };
}

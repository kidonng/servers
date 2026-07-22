{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    determinate.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "https://flakehub.com/f/nix-community/disko/1.13.0";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "https://flakehub.com/f/nix-community/impermanence/0.1.203";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "https://flakehub.com/f/Mic92/sops-nix/0.1.1226";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
  };

  outputs = { ... }@inputs: {
    nixosConfigurations = {
      dmit-lax = import ./hosts/dmit-lax { inherit inputs; };
      oracle-sjc = import ./hosts/oracle-sjc { inherit inputs; };
    };
  };
}

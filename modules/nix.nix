{ pkgs, ... }:

{
  nix = {
    package = pkgs.lixPackageSets.stable.lix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
}

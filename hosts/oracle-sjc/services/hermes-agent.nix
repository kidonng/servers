{ pkgs, ... }:

{
  # Prebuilt binary compat
  programs.nix-ld.enable = true;
  # Shebang compat
  services.envfs.enable = true;

  environment.systemPackages = with pkgs; [
    chromium
    git
    nodejs
    ripgrep
    uv

    # node-gyp deps
    gcc
    gnumake
    python3
  ];

  users.users.kiki = {
    isNormalUser = true;
    linger = true;
  };

  environment.persistence."/persist" = {
    directories = [
      "/home"
    ];
  };
}

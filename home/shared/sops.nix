{ config, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  home = config.home.homeDirectory;
in {
  sops = {
    age.keyFile =
      if isDarwin
        then "${home}/Library/Application Support/sops/age/keys.txt"
        else "${home}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../sops/kamov.yaml;
  };
}

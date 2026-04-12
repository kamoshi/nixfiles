{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;
in
{
  programs.bash.bashrcExtra = ''
    [ -f "${home}/.ghcup/env" ] && . "${home}/.ghcup/env"
  '';
}

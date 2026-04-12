{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;
in
{
  programs.fish.shellInit = ''
    if test -d "${home}/.cargo/bin"
      set -p fish_user_paths "${home}/.cargo/bin"
    end
  '';

  programs.bash.bashrcExtra = ''
    [ -d "${home}/.cargo/bin" ] && export PATH="${home}/.cargo/bin:$PATH"
  '';
}

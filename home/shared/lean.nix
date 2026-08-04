{
  config,
  pkgs,
  ...
}:
let
  home = config.home.homeDirectory;
in
{
  home.packages = with pkgs; [
    elan
  ];

  programs.fish.shellInit = ''
    if test -d "${home}/.elan/bin"
      set -p fish_user_paths "${home}/.elan/bin"
    end
  '';

  programs.bash.bashrcExtra = ''
    [ -d "${home}/.elan/bin" ] && export PATH="${home}/.elan/bin:$PATH"
  '';
}

{ config, nightly, ... }:
let
  home = config.home.homeDirectory;
in
{

  home.packages = [
    # nightly.wasm-pack
  ];

  programs.fish.shellInit = ''
    if test -d "${home}/.cargo/bin"
      set -p fish_user_paths "${home}/.cargo/bin"
    end
    if test -d "${home}/.cache/cargo/bin"
      set -p fish_user_paths "${home}/.cache/cargo/bin"
    end
  '';

  programs.bash.bashrcExtra = ''
    [ -d "${home}/.cargo/bin" ] && export PATH="${home}/.cargo/bin:$PATH"
    [ -d "${home}/.cache/cargo/bin" ] && export PATH="${home}/.cache/cargo/bin:$PATH"
  '';
}

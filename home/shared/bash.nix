{ config, ... }:
let
  home = config.home.homeDirectory;
in {
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      python = "python3";
    };
    bashrcExtra = ''
      # Homebrew
      [ -f "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
      # Haskell ghcup
      [ -f "${home}/.ghcup/env" ] && . "${home}/.ghcup/env"
      # Rust cargo
      [ -d "${home}/.cargo/bin" ] && export PATH="${home}/.cargo/bin:$PATH"
    '';
    initExtra = ''
      PS1='\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

      export GPG_TTY=$(tty)

      # Run fish
      # https://wiki.archlinux.org/title/Fish#Modify_.bashrc_to_drop_into_fish
      # Adapted for both GNU and BSD ps
      if [[ $(ps -p $PPID -o comm= | awk -F/ '{print $NF}' | tr -d '-') != "fish" && -z ''${BASH_EXECUTION_STRING} && ''${SHLVL} == 1 ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION='''
        exec fish $LOGIN_OPTION
      fi
    '';
  };
}

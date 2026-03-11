{ config, ... }:
let
  home = config.home.homeDirectory;
in {
  programs.fish = {
    enable = true;

    shellAliases = {
      python = "python3";
    };

    shellInit = ''
      if test -d "${home}/nix/config/bin"
        fish_add_path ${home}/nix/config/bin
      end

      # Homebrew
      if test -f /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
      end

      # BEGIN opam configuration
      # This is useful if you're using opam as it adds:
      # - the correct directories to the PATH
      # - auto-completion for the opam binary
      # This section can be safely removed at any time if needed.
      test -r '${home}/.opam/opam-init/init.fish' && source '${home}/.opam/opam-init/init.fish' > /dev/null 2> /dev/null; or true
      # END opam configuration

      # Rust cargo
      if test -d "${home}/.cargo/bin"
        set -p fish_user_paths "${home}/.cargo/bin"
      end

      source ${./functions.fish}
    '';

    interactiveShellInit = ''
      set -g fish_key_bindings fish_vi_key_bindings
    '';
  };

  home.shell.enableFishIntegration = true;
}

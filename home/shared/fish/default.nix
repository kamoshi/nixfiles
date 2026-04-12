{ nightly, ... }:
{
  programs.fish = {
    enable = true;
    package = nightly.fish;

    shellAliases = {
      python = "python3";
    };

    shellInit = ''
      fish_add_path ~/bin
      fish_add_path ~/nix/dotfiles/bin

      if type -q sprinter
        sprinter completion fish | source
      end

      # Homebrew
      if test -f /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv)
      end

      source ${./functions.fish}
    '';

    interactiveShellInit = ''
      set -g fish_key_bindings fish_vi_key_bindings
    '';
  };

  home.shell.enableFishIntegration = true;
}

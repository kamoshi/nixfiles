{ config, pkgs, ... }:
let
  home = config.home.homeDirectory;
in
{
  home.packages = with pkgs; [
    dune
    opam
  ];

  # This is useful if you're using opam as it adds:
  # - the correct directories to the PATH
  # - auto-completion for the opam binary
  # This section can be safely removed at any time if needed.
  programs.fish.shellInit = ''
    test -r '${home}/.opam/opam-init/init.fish' && source '${home}/.opam/opam-init/init.fish' > /dev/null 2> /dev/null; or true
  '';

  programs.bash.bashrcExtra = ''
    if command -v opam &> /dev/null && [ -d "$HOME/.opam" ]; then
      eval $(opam env)
    fi
  '';
}

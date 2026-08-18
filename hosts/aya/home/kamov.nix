{ ... }:
{
  imports = [
    ../../../home/personal.nix
    ../../../home/core.nix
    ../../../home/sops.nix
    ../../../home/bash.nix
    ../../../home/fish
    ../../../home/nvim.nix
    ../../../home/syncthing.nix
    ../../../home/ocaml.nix
    ../../../home/haskell.nix
    ../../../home/lean.nix
    ../../../home/opencode.nix
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

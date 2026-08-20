{ pkgs, nightly, ... }:
let
  nick = "kamov";
  home = "/home/${nick}";
in
{
  imports = [
    ./backup.nix
    ../../../../home/personal.nix
    ../../../../home/core.nix
    ../../../../home/bash.nix
    ../../../../home/fish
    ../../../../home/nvim.nix
    ../../../../home/syncthing.nix
    ../../../../home/rust.nix
    # ../../../home/ocaml.nix
    # ../../../home/haskell.nix
    # ../../../home/lean.nix
    # ../../../home/opencode.nix
  ];

  home = {
    username = nick;
    homeDirectory = home;
  };

  sops = {
    age.keyFile = "${home}/.config/sops/age/momiji-kamov.txt";
    defaultSopsFile = ./sops.yaml;
  };

  home.packages = with pkgs; [
    anki
    discord
    nightly.codex
    nil
    nixd
    vlc
    zed-editor
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

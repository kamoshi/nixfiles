{
  config,
  rolling,
  pkgs,
  utils,
  ...
}:
let
  nick = "kamov";
  home = "/home/${nick}";

  pkgsRelease = with pkgs; [
    android-tools
    blender
    calibre
    feishin
    ffmpeg-full
    google-chrome
    lazygit
    libreoffice
    nil
    nixd
    nixfmt
    obs-studio
    osu-lazer-bin
    vlc
    wl-clipboard
    zed-editor
  ];

  pkgsRolling = with rolling; [
    anki
    antigravity-cli
    codex
    piper
    slint-lsp
    wineWow64Packages.staging
  ];
in
{
  imports = [
    ./backup.nix
    ./flatpak.nix
    ./plasma.nix
    ./unsloth.nix

    ../../../../home/git.nix
    ../../../../home/bash.nix
    ../../../../home/fish
    ../../../../home/nvim.nix
    ../../../../home/syncthing.nix
    ../../../../home/rust.nix
  ];

  home = {
    username = nick;
    homeDirectory = home;

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
      # # Building this configuration will create a copy of 'dotfiles/screenrc' in
      # # the Nix store. Activating the configuration will then make '~/.screenrc' a
      # # symlink to the Nix store copy.
      # ".screenrc".source = dotfiles/screenrc;

      # # You can also set the file content immediately.
      # ".gradle/gradle.properties".text = ''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # '';
    }
    // utils.home.symlink config [
      ".XCompose"
    ];
  };

  xdg.configFile = utils.home.xdgSymlink config [
    # zed
    "zed/settings.json"
  ];

  sops = {
    age.keyFile = "${home}/.config/sops/age/momiji-kamov.txt";
    defaultSopsFile = ./sops.yaml;
  };

  home.packages = pkgsRelease ++ pkgsRolling;

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

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

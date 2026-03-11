{ config, pkgs, utils, ... }:
{
  imports = [
    ../shared/core.nix
    ../shared/sops.nix
    ../shared/bash.nix
    ../shared/fish
    ../shared/nvim.nix
    ../shared/syncthing.nix
  ];

  home.username = "kamov";

  sops.secrets = {
    "syncthing/workspace" = {};
    "syncthing/obsidian" = {};
    "syncthing/photos" = {};
  };

  programs.git = {
    enable = true;

    signing = {
      key = "191CBFF5F72ECAFD";
      signByDefault = true;
    };

    settings = {
      user.name  = "Maciej Jur";
      user.email = "maciej@kamoshi.org";

      init.defaultBranch = "main";
    };
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  } // utils.home.symlink config [
    ".XCompose"
  ];

  xdg.configFile = utils.home.symlink config [
    # zed
    "zed/settings.json"
  ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    age
    bat
    biome
    deno
    dust
    ffmpeg-full
    gemini-cli
    mupdf-headless
    ncdu
    nixd
    ripgrep
    sops
    typst
    uv

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/kamov/etc/profile.d/hm-session-vars.sh
  #
  # home.sessionVariables = {};

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.
}

{ self, pkgs, device,... }:
let
  user = "kamov";
in {
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  # environment.systemPackages = with pkgs; [
  # ]

  # Enable alternative shell support in nix-darwin.
  programs.fish.enable = true;

  networking = {
    computerName = device.name;
    hostName = device.key;
    localHostName = device.key;
  };

  users.users.${user}.home = "/Users/${user}";

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.upgrade = true;

    taps = [];
    brews = [
      "gpg"
      "dosbox-x"
      "pinentry-mac"
      "python"
      "mpv"
    ];
    casks = [
      "steam"
      "anki"
      "zed"
      "ghostty"
      "obsidian"
      "krita"
      "calibre"
      "netnewswire"
      "discord"
      "spotify"
      "transmission"
      "google-chrome"
      "vlc"
      "the-unarchiver"
      # proton
      "proton-mail"
      "proton-pass"
    ];
  };

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  security.pam.services.sudo_local.touchIdAuth = true;

  system = {
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 6;

    # Set Git commit hash for darwin-version.
    configurationRevision = self.rev or self.dirtyRev or null;

    primaryUser = user;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;
      };

      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        FXEnableExtensionChangeWarning = false;
        _FXShowPosixPathInTitle = true;  # Show full path in finder window title
        AppleShowAllFiles = true;        # Always show hidden files
        FXPreferredViewStyle = "Nlsv";   # Default to List View (much faster/organized)
      };

      dock = {
        autohide = true;
        show-recents = true;
        launchanim = true;
        orientation = "bottom";
        tilesize = 48;
        autohide-delay = 0.0;

        persistent-apps = [
          "/System/Applications/System Settings.app"
          "/Applications/Anki.app"
          "/Applications/NetNewsWire.app"
          "/Applications/Firefox.app"
          "/Applications/Obsidian.app"
          "/Applications/calibre.app"
          "/Applications/Proton Mail.app"
          "/Applications/Proton Pass.app"
          "/Applications/Ghostty.app"
          "/Applications/Zed.app"
          # "/Applications/Discord.app"
          # "/Applications/Spotify.app"
        ];
      };
    };
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = device.arch;
}

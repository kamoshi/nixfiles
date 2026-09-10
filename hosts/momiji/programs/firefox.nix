{ rolling, ... }:

{
  programs.firefox = {
    enable = true;
    package = rolling.firefox-devedition;

    preferences = {
      "widget.use-xdg-desktop-portal.file-picker" = 1;
    };

    policies = {
      HttpsOnlyMode = "enabled";

      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
      };

      # Privacy and experiments
      # DisableTelemetry = true;
      # DisableFirefoxStudies = true;
      DisablePocket = true;

      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
        Locked = false;
      };

      FirefoxHome = {
        Search = true;
        TopSites = false;
        SponsoredTopSites = false;
        Pocket = false;
        Stories = false;
        SponsoredPocket = false;
        SponsoredStories = false;
        Snippets = false;
        Locked = false;
      };

      FirefoxSuggest = {
        SponsoredSuggestions = false;
        ImproveSuggest = false;
        Locked = false;
      };
    };
  };
}

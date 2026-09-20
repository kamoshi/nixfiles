{
  programs.plasma = {
    enable = true;

    kwin.effects.wobblyWindows.enable = true;

    panels = [
      {
        location = "bottom";
        height = 46;
        floating = false;
        lengthMode = "fill";
        hiding = "none";
        # DP-1: the right-hand monitor, configured as the primary Plasma screen.
        screen = 0;

        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.pager"
          {
            iconTasks = {
              launchers = [
                "applications:systemsettings.desktop"
                "applications:org.kde.dolphin.desktop"
                "applications:firefox-devedition.desktop"
              ];
              appearance.fill = true;
            };
          }
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          {
            digitalClock = {
              time.format = "24h";
              time.showSeconds = "never";
              date = {
                enable = true;
                format.custom = "dd.MM.yyyy";
                position = "belowTime";
              };
            };
          }
          "org.kde.plasma.showdesktop"
        ];
      }
    ];
  };
}

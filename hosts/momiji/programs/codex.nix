{ ... }:
{
  programs.codexDesktopLinux = {
    enable = true;

    # (Optional) Enable curated Linux enhancements/tweaks:
    # Examples: "ui-tweaks", "read-aloud", "frameless-titlebar", "shared-app-server-socket"
    linuxFeatures = [ "ui-tweaks" ];

    # (Optional) If you want the computer-use UI feature:
    # computerUseUi.enable = true;
  };
}

{ nightly, ... }:
{
  programs.steam = {
    enable = true;

    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    localNetworkGameTransfers.openFirewall = false;

    # Make GE-Proton available in Steam's compatibility-tool selector.
    extraCompatPackages = with nightly; [ proton-ge-bin ];

    # Useful for applying Winetricks fixes to Proton prefixes.
    protontricks.enable = true;
  };

  # Games can opt in with the Steam launch option: gamemoderun %command%
  programs.gamemode.enable = true;
}

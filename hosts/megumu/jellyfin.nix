{ ... }:
let
  port = 8096; # Jellyfin default port
in {
  services.jellyfin = {
    enable = true;
    user = "jellyfin";

    # We don't want the whole world to see it.
    openFirewall = false;
  };

  networking.firewall = {
    # Open ONLY for WireGuard
    interfaces."wg0" = {
      allowedTCPPorts = [ port ];
    };
  };

  # Ensure Jellyfin can see the SSHFS mount
  systemd.services.jellyfin = {
    # Force Jellyfin to wait until /data is actually mounted
    requires = [ "data.mount" ];
    after = [ "data.mount" "network-online.target" ];
  };

  services.nginx = {
    enable = true;

    virtualHosts."jellyfin.internal" = {
      listen = [
        { addr = "10.0.0.1"; port = 80; }
        { addr = "127.0.0.1"; port = 80; }
      ];

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        proxyWebsockets = true;
      };

      forceSSL = false;
      enableACME = false;
    };
  };

  services.blocky = {
    settings.customDNS.mapping."jellyfin.internal" = "10.0.0.1";
  };
}

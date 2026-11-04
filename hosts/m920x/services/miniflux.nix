{ config, ... }:
{
  sops.secrets = {
    miniflux = {
      owner = "root";
      group = "root";
      mode = "0640";
      restartUnits = [ "miniflux.service" ];
    };
  };

  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets."miniflux".path;

    config = {
      LISTEN_ADDR = "/run/miniflux/server.sock";
      BASE_URL = "https://rss.kamoshi.org";
    };
  };

  systemd.services = {
    # Allow caddy to communicate with miniflux socket
    caddy.serviceConfig = {
      SupplementaryGroups = [ "miniflux" ];
    };
  };

  services.blocky = {
    settings.customDNS.mapping."rss.internal" = "10.1.0.1";
  };

  services.caddy = {
    enable = true;

    virtualHosts."rss.internal".extraConfig = ''
      bind 10.1.0.1 10.0.0.5
      tls internal
      reverse_proxy unix//run/miniflux/server.sock
    '';
  };
}

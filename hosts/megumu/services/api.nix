{ config, ... }:
let
  port = 4321;
in {
    sops.secrets.kotori = {
      mode = "0400";
    };

    services.rss-summarizer = {
      enable = true;
      port = port;
      portInternal = port + 1;
      envFile = config.sops.secrets.kotori.path;
    };

  services.nginx = {
    enable = true;

    virtualHosts."api.kamoshi.org" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString port}";
      };
    };
  };
}

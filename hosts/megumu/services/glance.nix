{ config, pkgs, ... }:
let
  port = 9292;
  domain = "glance.kamoshi.org";
in {
  services.glance = {
    enable = true;
    settings = {
      server.port = port;

      pages = [
        {
          name = "Home";
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "extension";
                  title = "News Summary";
                  url = "https://api.kamoshi.org/summary";
                  allow-potentially-dangerous-html = true;
                  cache = "1s";
                }
              ];
            }
          ];
        }
      ];
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
    };
  };
}

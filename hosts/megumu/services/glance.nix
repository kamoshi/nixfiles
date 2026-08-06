{ config, inventory, pkgs, ... }:
let
  endpoint = inventory.endpoints.glance;
  fukurouEndpoint = inventory.endpoints.fukurou;
in {
  services.glance = {
    enable = true;
    settings = {
      server.port = endpoint.port;

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
                  url = "https://${fukurouEndpoint.domains.external}/summary";
                  allow-potentially-dangerous-html = true;
                  cache = "1s";
                }
              ];
            }
            # Sidebar Column (Right side)
            {
              size = "small";
              widgets = [
                {
                  type = "weather";
                  title = "Warszawa";
                  location = "Warsaw";
                  units = "metric";
                }
                {
                  type = "weather";
                  title = "Wrocław";
                  location = "Wroclaw";
                  units = "metric";
                }
                {
                  type = "weather";
                  title = "Leszno";
                  location = "Leszno";
                  units = "metric";
                }
              ];
            }
          ];
        }
      ];
    };
  };

  services.nginx.virtualHosts.${endpoint.domains.external} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${endpoint.bind}:${toString endpoint.port}";
    };
  };
}

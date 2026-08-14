{ inventory, ... }:
let
  endpoint = inventory.endpoints.karasu;
in
{
  services.karasu = {
    enable = true;
    bind = endpoint.bind;
    port = endpoint.port;
  };

  services.nginx.virtualHosts.${endpoint.domains.external} = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://${endpoint.bind}:${toString endpoint.port}";
  };
}

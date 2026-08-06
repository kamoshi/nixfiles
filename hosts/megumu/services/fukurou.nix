{ config, device, inventory, ... }:
let
  endpoint = inventory.endpoints.fukurou;
in
{
  sops.secrets.kotori = {
    mode = "0400";
  };

  services.fukurou = {
    enable = true;
    port = endpoint.port;
    portInternal = endpoint.internalPort;
    envFile = config.sops.secrets.kotori.path;
  };

  services.caddy = {
    enable = true;
    virtualHosts.${endpoint.domains.internal}.extraConfig = ''
      bind ${device.vpn.ip}
      tls internal
      reverse_proxy ${endpoint.bind}:${toString endpoint.internalPort}
    '';
  };

  services.blocky = {
    settings.customDNS.mapping.${endpoint.domains.internal} = device.vpn.ip;
  };

  services.nginx = {
    enable = true;

    virtualHosts.${endpoint.domains.external} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://${endpoint.bind}:${toString endpoint.port}";
      };
    };
  };
}

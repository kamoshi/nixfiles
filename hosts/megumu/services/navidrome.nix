{ device, inventory, ... }:
let
  endpoint = inventory.endpoints.navidrome;
in {
  services.caddy = {
    enable = true;
    virtualHosts.${endpoint.domains.internal}.extraConfig = ''
      bind ${device.vpn.ip}
      tls internal
      reverse_proxy ${endpoint.bind}:${toString endpoint.port}
    '';
  };

  services.blocky = {
    settings.customDNS.mapping.${endpoint.domains.internal} = device.vpn.ip;
  };

  services.nginx.virtualHosts.${endpoint.domains.external} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://${endpoint.bind}:${toString endpoint.port}";
    };
  };
}

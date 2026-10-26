{ device, inventory, pkgs, rolling, ... }:
let
  endpoint = inventory.endpoints.calibre;
in
{
  services.calibre-web = {
    enable = true;

    listen.ip = endpoint.bind;
    listen.port = endpoint.port;
    options = {
      calibreLibrary = inventory.sync.calibre;
      enableBookUploading = false;
    };
  };

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
}

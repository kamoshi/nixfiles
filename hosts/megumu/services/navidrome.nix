{ device, inventory, ... }:
let
  endpoint = inventory.endpoints.navidrome;
in {
  services.navidrome = {
    enable = true;
    settings = {
      Address = endpoint.bind;
      Port = endpoint.port;
      MusicFolder = inventory.sync.music;
      EnforceNonRootUser = true;
      EnableTranscodingConfig = false;

      # EnableSharing = false;
      DefaultShareExpiration = "24h";
    };
  };

  systemd.services.navidrome = {
    # Force Navidrome to wait until the storagebox is actually mounted,
    # and stop it immediately if storagebox unmounts (e.g. during nixos-rebuild)
    bindsTo = [ "storagebox.service" ];
    after = [ "storagebox.service" ];
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

  services.nginx.virtualHosts.${endpoint.domains.external} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://${endpoint.bind}:${toString endpoint.port}";
    };
  };
}

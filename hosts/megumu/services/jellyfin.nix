{ device, inventory, ... }:
let
  endpoint = inventory.endpoints.jellyfin;
in {
  services.jellyfin = {
    enable = true;
    user = "jellyfin";

    # We don't want the whole world to see it.
    openFirewall = false;
  };

  networking.firewall = {
    # Open ONLY for WireGuard
    interfaces."gensokyo" = {
      allowedTCPPorts = [ endpoint.port ];
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts.${endpoint.domains.internal}.extraConfig = ''
      bind ${device.vpn.ip}
      tls internal
      encode zstd gzip
      reverse_proxy ${endpoint.bind}:${toString endpoint.port} {
        flush_interval -1
      }
    '';
  };

  services.blocky = {
    settings.customDNS.mapping.${endpoint.domains.internal} = device.vpn.ip;
  };
}

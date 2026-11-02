{ ... }:
{

  networking.firewall.allowedTCPPorts = [
    # http
    80 443
  ];

  services.caddy = {
    enable = true;

    virtualHosts."ca.internal".extraConfig = ''
      tls internal

      acme_server {
        ca local
        resolvers 10.0.0.1
        challenges http-01

        allow {
          domains music.internal photos.internal
        }
      }
    '';
  };
}

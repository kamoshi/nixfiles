{ ... }:
let
  port = 4533;
in
{
  services.caddy = {
    enable = true;
    virtualHosts."music.internal" = {
      extraConfig = ''
        bind 10.0.0.1

        log {
            level INFO
        }

        tls {
          issuer acme {
            dir https://ca.internal/acme/local/directory
            trusted_roots /etc/caddy/ca-root.crt
          }
        }

        reverse_proxy 10.0.0.5:${toString port}
      '';
    };
  };

  services.blocky = {
    settings.customDNS.mapping."music.internal" = "10.0.0.1";
  };

  services.nginx.virtualHosts."music.kamoshi.org" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://10.0.0.5:${toString port}";
    };
  };
}

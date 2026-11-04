{ ... }:
{
  networking.hosts."10.0.0.5" = [ "rss.internal" ];

  services.blocky = {
    settings.customDNS.mapping."rss.internal" = "10.0.0.5";
  };

  services.nginx.virtualHosts."rss.kamoshi.org" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "https://rss.internal";

      # Prevent NixOS from adding its own proxy_set_header directives.
      recommendedProxySettings = false;

      extraConfig = ''
        proxy_ssl_trusted_certificate /etc/caddy/ca-root.crt;
        proxy_ssl_verify on;
        proxy_ssl_server_name on;
        proxy_ssl_name rss.internal;

        proxy_set_header Host rss.internal;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $hostname;
      '';
    };
  };
}

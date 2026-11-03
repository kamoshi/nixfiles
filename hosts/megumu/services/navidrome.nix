{ ... }:
{
  networking.hosts."10.0.0.5" = [ "music.internal" ];

  services.blocky = {
    settings.customDNS.mapping."music.internal" = "10.0.0.5";
  };

  services.nginx.virtualHosts."music.kamoshi.org" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "https://music.internal";
      proxyWebsockets = true;

      # Prevent NixOS from adding its own proxy_set_header directives.
      recommendedProxySettings = false;

      extraConfig = ''
        proxy_ssl_trusted_certificate /etc/caddy/ca-root.crt;
        proxy_ssl_verify on;
        proxy_ssl_server_name on;
        proxy_ssl_name music.internal;

        proxy_set_header Host music.internal;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $hostname;
      '';
    };
  };
}

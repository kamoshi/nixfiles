{ ... }:
let
  port = 5555;
in {
  services.unbound.settings.server.local-data = [
    ''"suzume.internal. 3600 IN CNAME m920x.internal."''
  ];

  services.caddy = {
    enable = true;

    virtualHosts."suzume.internal".extraConfig = ''
      bind 10.1.0.1 [fd00::1] 10.0.0.5
      tls internal
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };

  services.suzume = {
    enable = true;
    address = "127.0.0.1";
    port = port;
  };
}

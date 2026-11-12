{ ... }:
let
  port = 5555;
in {
  services.blocky = {
    settings.customDNS.mapping."suzume.internal" = "10.1.0.1";
  };

  services.caddy = {
    enable = true;

    virtualHosts."suzume.internal".extraConfig = ''
      bind 10.1.0.1 10.0.0.5
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

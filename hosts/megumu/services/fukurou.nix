{ config, ... }:
let
  domainExternal = "api.kamoshi.org";
  domainInternal = "fukurou.internal";
  portExternal = 4321;
  portInternal = 4322;
in
{
  sops.secrets.kotori = {
    mode = "0400";
  };

  services.fukurou = {
    enable = true;
    port = portExternal;
    portInternal = portInternal;
    envFile = config.sops.secrets.kotori.path;
  };

  services.caddy = {
    enable = true;
    virtualHosts.${domainInternal}.extraConfig = ''
      bind 10.0.0.1
      tls internal
      reverse_proxy 127.0.0.1:${toString portInternal}
    '';
  };

  services.blocky = {
    settings.customDNS.mapping.${domainInternal} = "10.0.0.1";
  };

  services.nginx = {
    enable = true;

    virtualHosts.${domainExternal} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString portExternal}";
      };
    };
  };
}

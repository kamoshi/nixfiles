{ ... }:
let
  listenAddress = "10.0.0.5";
  immichPort = 2283;
  navidromePort = 4533;
  immichHost = "photos.m920x.internal";
  navidromeHost = "music.m920x.internal";
  listen = port: [
    {
      addr = listenAddress;
      inherit port;
      ssl = false;
    }
  ];
in
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    virtualHosts.${immichHost} = {
      serverAliases = [
        "photos.internal"
        "photos.kamoshi.org"
      ];
      listen = listen 80 ++ listen immichPort;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString immichPort}";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_request_buffering off;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          send_timeout 600s;
        '';
      };
    };

    virtualHosts.${navidromeHost} = {
      serverAliases = [
        "music.internal"
        "music.kamoshi.org"
      ];
      listen = listen 80 ++ listen navidromePort;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString navidromePort}";
        proxyWebsockets = true;
      };
    };
  };

  networking.firewall.interfaces.gensokyo.allowedTCPPorts = [
    80
    immichPort
    navidromePort
  ];
}

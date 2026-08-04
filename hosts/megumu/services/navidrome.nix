{ ... }:
let
  domainInternal = "music.internal";
  domainExternal = "music.kamoshi.org";
  bind = "127.0.0.1";
  port = 4533;
in {
  services.navidrome = {
    enable = true;
    settings = {
      Address = bind;
      Port = port;
      MusicFolder = "/data/music/";
      EnforceNonRootUser = true;
      EnableTranscodingConfig = false;

      # EnableSharing = false;
      DefaultShareExpiration = "24h";
    };
  };

  systemd.services.navidrome = {
    # Force Navidrome to wait until /data is actually mounted,
    # and stop it immediately if storagebox unmounts (e.g. during nixos-rebuild)
    bindsTo = [ "storagebox.service" ];
    after = [ "storagebox.service" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts.${domainInternal}.extraConfig = ''
      bind 10.0.0.1
      tls internal
      reverse_proxy ${bind}:${toString port}
    '';
  };

  services.blocky = {
    settings.customDNS.mapping.${domainInternal} = "10.0.0.1";
  };

  services.nginx.virtualHosts.${domainExternal} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://${bind}:${toString port}";
    };
  };
}

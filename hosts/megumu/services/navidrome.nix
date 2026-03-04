{ ... }:
let
  domain = "navidrome.internal";
  bind = "10.0.0.1";
  port = 4533;
in {
  services.navidrome = {
    enable = true;
    settings = {
      Address = bind;
      Port = port;
      MusicFolder = "/data/navidrome/";
    };
  };

  systemd.services.navidrome = {
    # Force Navidrome to wait until /data is actually mounted
    requires = [ "storagebox.service" ];
    after = [ "storagebox.service" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts.${domain}.extraConfig = ''
      bind 10.0.0.1
      tls internal
      reverse_proxy ${bind}:${toString port}
    '';
  };

  services.blocky = {
    settings.customDNS.mapping.${domain} = "10.0.0.1";
  };
}

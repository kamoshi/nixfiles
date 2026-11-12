{ ... }:
{
  users.users.jellyfin.extraGroups = [ "render" "video" ];

  networking.firewall = {
    enable = true;

    allowedTCPPorts = [ 8096 ];
    allowedUDPPorts = [ ];
  };

  services.jellyfin = {
    enable = true;
    openFirewall = false;

    dataDir = "/data/jellyfin";
    configDir = "/data/jellyfin/config";
    cacheDir = "/data/jellyfin/cache";
    logDir = "/data/jellyfin/log";

    hardwareAcceleration = {
      enable = true;
      type = "vaapi";
      device = "/dev/dri/renderD128";
    };
  };

  services.blocky = {
    settings.customDNS.mapping."media.internal" = "10.1.0.1";
  };

  services.caddy = {
    enable = true;

    virtualHosts."media.internal".extraConfig = ''
      bind 10.1.0.1 10.0.0.5
      tls internal
      reverse_proxy 127.0.0.1:8096
    '';
  };
}

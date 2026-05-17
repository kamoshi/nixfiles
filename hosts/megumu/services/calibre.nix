{ pkgs, nightly, ... }:
let
  domain = "calibre.internal";
  bind = "10.0.0.1";
  port = 9998;
in
{
  services.calibre-web = {
    enable = true;

    package = nightly.calibre-web;

    listen.ip = bind;
    listen.port = port;
    options = {
      calibreLibrary = "/data/sync/calibre";
      enableBookUploading = false;
    };
  };

  systemd.services.calibre-web = {
    # Force Calibre to wait until /data is actually mounted,
    # and stop it immediately if storagebox unmounts (e.g. during nixos-rebuild)
    bindsTo = [ "storagebox.service" ];
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

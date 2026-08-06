{ device, inventory, pkgs, nightly, ... }:
let
  endpoint = inventory.endpoints.calibre;
in
{
  services.calibre-web = {
    enable = true;

    listen.ip = endpoint.bind;
    listen.port = endpoint.port;
    options = {
      calibreLibrary = inventory.sync.calibre;
      enableBookUploading = false;
    };
  };

  systemd.services.calibre-web = {
    # Force Calibre to wait until the storagebox is actually mounted,
    # and stop it immediately if storagebox unmounts (e.g. during nixos-rebuild)
    bindsTo = [ "storagebox.service" ];
    after = [ "storagebox.service" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts.${endpoint.domains.internal}.extraConfig = ''
      bind ${device.vpn.ip}
      tls internal
      reverse_proxy ${endpoint.bind}:${toString endpoint.port}
    '';
  };

  services.blocky = {
    settings.customDNS.mapping.${endpoint.domains.internal} = device.vpn.ip;
  };
}

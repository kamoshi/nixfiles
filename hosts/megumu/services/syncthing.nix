{ config, device, inventory, mesh, ... }:
let
  endpoint = inventory.endpoints.syncthing;
in
{
  services.syncthing = {
    enable = true;
    user = "kamov";
    group = "users";
    openDefaultPorts = false;
    configDir = "/home/kamov/.config/syncthing";
    guiAddress = "${endpoint.bind}:${toString endpoint.port}";

    settings = {
      # The declarative configuration updater uses guiAddress for the REST API.
      gui.enabled = true;

      inherit (mesh config) devices folders;
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts.${endpoint.domains.internal}.extraConfig = ''
      bind ${device.vpn.ip}
      tls internal
      reverse_proxy ${endpoint.bind}:${toString endpoint.port}
    '';
  };

  services.blocky.settings.customDNS.mapping.${endpoint.domains.internal} = device.vpn.ip;

  # Public Syncthing synchronization ports.
  # Source: https://docs.syncthing.net/users/firewall.html
  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 ];
    interfaces.gensokyo.allowedTCPPorts = [ endpoint.port ];
  };

  systemd.services.syncthing = {
    bindsTo = [
      "storagebox.service"
      "storagebox_enc.service"
    ];
    after = [
      "storagebox.service"
      "storagebox_enc.service"
    ];
    environment.STNODEFAULTFOLDER = "true";
  };
}

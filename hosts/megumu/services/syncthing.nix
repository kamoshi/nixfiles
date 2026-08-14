{ config, inventory, mesh, ... }:
let
  endpoint = inventory.endpoints.syncthing;
in
{
  assertions = [
    {
      assertion = endpoint.bind == "127.0.0.1";
      message = "The Syncthing GUI/API must remain bound to loopback for the configuration updater.";
    }
  ];

  services.syncthing = {
    enable = true;
    user = "kamov";
    group = "users";
    openDefaultPorts = false;
    configDir = "/home/kamov/.config/syncthing";
    guiAddress = "${endpoint.bind}:${toString endpoint.port}";

    settings = {
      # The declarative configuration updater needs the REST API served by
      # the GUI. The loopback-only address keeps it local to this machine.
      gui.enabled = true;

      inherit (mesh config) devices folders;
    };
  };

  # Public Syncthing synchronization ports.
  # Source: https://docs.syncthing.net/users/firewall.html
  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 ];
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

{ config, pkgs, lib, mesh, ... }:
let
  cfg = config.kamov.syncthing;
in {
  options.kamov.syncthing = {
    enable = lib.mkEnableOption "Enable Syncthing";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8384;
      description = "Port for the Syncthing GUI.";
    };

    bind = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "IP for Syncthing GUI to bind to.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "kamov";
      description = "User to run Syncthing under.";
    };

    configDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/kamov/.config/syncthing";
      description = "Configuration directory for Syncthing.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = cfg.user;
      group = "users";
      openDefaultPorts = false;
      configDir = cfg.configDir;
      guiAddress = "${cfg.bind}:${toString cfg.port}";

      settings = {
        gui = {
          enabled = true;
          user = "kamov";
          password = "kamov";
        };

        inherit (mesh config) devices folders;
      };
    };

    # Syncthing ports: 8384 for remote access to GUI
    # 22000 TCP and/or UDP for sync traffic
    # 21027/UDP for discovery
    # source: https://docs.syncthing.net/users/firewall.html
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [ 22000 21027 ];
      interfaces.wg0.allowedTCPPorts = [ cfg.port ];
    };

    # Don't create default ~/Sync folder
    systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";

    services.nginx = {
      enable = true;

      virtualHosts."syncthing.internal" = {
        listen = [
          { addr = "10.0.0.1"; port = 80; }
          { addr = "127.0.0.1"; port = 80; }
        ];

        locations."/" = {
          proxyPass = "http://${cfg.bind}:${toString cfg.port}";
          proxyWebsockets = true;
        };

        forceSSL = false;
        enableACME = false;
      };
    };

    services.blocky = {
      settings.customDNS.mapping."syncthing.internal" = "10.0.0.1";
    };
  };
}

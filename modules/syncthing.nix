{ config, device, pkgs, lib, mesh, ... }:
let
  cfg = config.kamov.syncthing;
in {
  options.kamov.syncthing = {
    enable = lib.mkEnableOption "Enable Syncthing";

    port = lib.mkOption {
      type = lib.types.port;
      description = "Port for the Syncthing GUI.";
    };

    bind = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "IP for Syncthing GUI to bind to.";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Internal domain for the Syncthing GUI.";
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
        gui.enabled = false;

        # gui = {
        #   enabled = true;
        #   user = "kamov";
        #   # Store a bcrypt hash in SOPS; never put a plaintext password
        #   # in the Nix configuration.
        #   password = "<sops-managed-bcrypt-hash>";
        # };

        inherit (mesh config) devices folders;
      };
    };

    # Public Syncthing synchronization ports.
    # source: https://docs.syncthing.net/users/firewall.html
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [ 22000 ];
    };

    # Don't create default ~/Sync folder
    systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";

    # services.caddy = {
    #   enable = true;
    #   virtualHosts.${cfg.domain}.extraConfig = ''
    #     bind ${device.vpn.ip}
    #     tls internal
    #     reverse_proxy ${cfg.bind}:${toString cfg.port}
    #   '';
    # };

    # services.blocky = {
    #   settings.customDNS.mapping.${cfg.domain} = device.vpn.ip;
    # };

  };
}

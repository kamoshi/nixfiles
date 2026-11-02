{ ... }:
let
  port = 4533;
  music = "/data/music";
in
{
  services.navidrome = {
    enable = true;
    settings = {
      Address = "unix:/server.socket";
      UnixSocketPerm = "0660";
      MusicFolder = music;
      EnforceNonRootUser = true;
      EnableTranscodingConfig = false;
      Plugins.Enabled = false;
      DefaultShareExpiration = "24h";
    };
  };

  systemd.services = {
    # The NixOS module already confines Navidrome to its state and read-only
    # music paths; prevent privilege gains from any child process as well.
    navidrome.serviceConfig = {
      NoNewPrivileges = true;
      RestrictSUIDSGID = true;
    };
    # Allow caddy to communicate with navidrome socket
    caddy.serviceConfig.SupplementaryGroups = [ "navidrome" ];
  };

  # Syncthing runs as kamov; setgid gives synced files Navidrome's group.
  # Only kamov and Navidrome can traverse the library directory.
  systemd.tmpfiles.rules = [
    "d ${music} 2770 kamov navidrome -"
    "z ${music} 2770 kamov navidrome -"
  ];

  networking.firewall.interfaces = {
    gensokyo.allowedTCPPorts = [ port ];
    mesh.allowedTCPPorts = [ port ];
  };

  services.caddy = {
    enable = true;

    virtualHosts = {
      ":4533" = {
        extraConfig = ''
          bind 10.0.0.5
          reverse_proxy unix//run/navidrome/server.socket
        '';
      };
      "music.internal" = {
        extraConfig = ''
          bind 10.1.0.1
          tls internal
          reverse_proxy unix//run/navidrome/server.socket
        '';
      };
    };
  };
}

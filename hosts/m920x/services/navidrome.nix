{ ... }:
let
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
      PrivateNetwork = true;
      RestrictAddressFamilies = [ "AF_UNIX" ];
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

  services.blocky = {
    settings.customDNS.mapping."music.internal" = "10.1.0.1";
  };

  services.caddy = {
    enable = true;

    virtualHosts."music.internal".extraConfig = ''
      bind 10.1.0.1 10.0.0.5
      tls internal
      reverse_proxy unix//run/navidrome/server.socket
    '';
  };
}

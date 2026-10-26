{ ... }:
let
  port = 4533;
  music = "/data/music";
in
{
  services.navidrome = {
    enable = true;
    settings = {
      Address = "10.0.0.5";
      Port = port;
      MusicFolder = music;
      EnforceNonRootUser = true;
      EnableTranscodingConfig = false;
      Plugins.Enabled = false;
      DefaultShareExpiration = "24h";
    };
  };

  # The NixOS module already confines Navidrome to its state and read-only
  # music paths; prevent privilege gains from any child process as well.
  systemd.services.navidrome.serviceConfig = {
    NoNewPrivileges = true;
    RestrictSUIDSGID = true;
  };

  # Syncthing runs as kamov; setgid gives synced files Navidrome's group.
  # Only kamov and Navidrome can traverse the library directory.
  systemd.tmpfiles.rules = [
    "d ${music} 2770 kamov navidrome -"
    "z ${music} 2770 kamov navidrome -"
  ];

  networking.firewall.interfaces.gensokyo.allowedTCPPorts = [ port ];
}

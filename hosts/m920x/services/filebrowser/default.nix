{ pkgs, rolling, ... }:

{
  services.unbound.settings.server.local-data = [
    ''"files.internal. 3600 IN CNAME m920x.internal."''
  ];

  systemd.services.filebrowser-quantum = {
    description = "FileBrowser Quantum";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    path = [ pkgs.ffmpeg-headless ];

    serviceConfig = {
      Type = "simple";

      DynamicUser = true;
      Group = "caddy";

      StateDirectory = "filebrowser-quantum";
      StateDirectoryMode = "0700";

      RuntimeDirectory = "filebrowser-quantum";
      RuntimeDirectoryMode = "0710";

      UMask = "0007";
      WorkingDirectory = "/var/lib/filebrowser-quantum";

      ExecStart =
        "${rolling.filebrowser-quantum}/bin/filebrowser-quantum -c ${./config.yml}";

      Restart = "on-failure";
      RestartSec = "5s";

      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      RestrictSUIDSGID = true;

      ReadOnlyPaths = [ "/data/files" ];
    };
  };

  services.caddy = {
    enable = true;

    virtualHosts."files.internal".extraConfig = ''
      bind 10.1.0.1 10.0.0.5
      tls internal
      reverse_proxy unix//run/filebrowser-quantum/filebrowser.sock
    '';
  };
}

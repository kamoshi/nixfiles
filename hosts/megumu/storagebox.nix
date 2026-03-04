{ lib, pkgs, ... }:
let
  options = [
    "port=23"                    # Use the more robust interactive port

    "allow_other"                # Allow other users to access mount
    "reconnect"                  # Auto-reconnect on connection loss
    "ServerAliveInterval=15"     # Send keepalive every 15 seconds
    "ServerAliveCountMax=3"      # Drop connection after 3 failed keepalives

    "cache=yes"                  # Enable attribute and data caching
    "kernel_cache"               # Use kernel page cache for better performance
    "compression=no"             # Disable SSH compression (faster on good connections)
    "noatime"                    # Improve performance by disabling atime updates

    "max_read=131072"            # 128KB read buffer (good for streaming)
    "max_write=131072"           # 128KB write buffer (good for downloads)

    "BatchMode=yes"              # Non-interactive mode
    "TCPKeepAlive=yes"           # Enable TCP keepalive

    "IdentityFile=/root/.ssh/root@megumu"
    "StrictHostKeyChecking=accept-new"
  ];
in {
  systemd.services."storagebox" = {
    description = "Hetzner SSHFS Mount";

    wantedBy = [
      "multi-user.target"
    ];

    after = [
      "network-online.target"
      "time-sync.target"
      "blocky.service"
      "unbound.service"
    ];

    wants = [
      "network-online.target"
      "time-sync.target"
    ];

    requires = [
      "network-online.target"
      "blocky.service"
      "unbound.service"
    ];

    preStart = "mkdir -p /data";

    serviceConfig = {
      # Use forking so systemd waits until the mount is fully established
      # before considering the service started. This prevents race conditions
      # with services like Navidrome that depend on this mount.
      Type = "forking";
      ExecStart = ''
        ${pkgs.sshfs}/bin/sshfs u489674@u489674.your-storagebox.de:megumu /data \
        -o ${lib.concatStringsSep "," options}
      '';
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u /data";
      Restart = "always";
      RestartSec = "30s";
    };
  };
}

{ pkgs, ... }:
let
  user = "u489674";
  host = "u489674.your-storagebox.de";
  port = 23;
  key = "/root/.ssh/root@megumu";
  cache = "/var/cache/rclone";
in {
  systemd.services."storagebox" = {
    description = "Hetzner Rclone Mount";

    wantedBy = [ "multi-user.target" ];

    after = [
      "network-online.target"
      "time-sync.target"
      "blocky.service"
      "unbound.service"
    ];

    wants = [
      "time-sync.target"
      "blocky.service"
      "unbound.service"
    ];

    requires = [
      "network-online.target"
    ];

    path = [ "/run/wrappers" ];

    preStart = ''
      ${pkgs.util-linux}/bin/umount -l /data 2>/dev/null || true
      mkdir -p /data
      mkdir -p ${cache}
    '';

    serviceConfig = {
      Type = "notify";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount :sftp:megumu /data \
        --sftp-user ${user} \
        --sftp-host ${host} \
        --sftp-port ${toString port} \
        --sftp-key-file ${key} \
        --allow-other \
        --cache-dir ${cache} \
        --vfs-cache-mode full \
        --vfs-cache-max-size 5G \
        --vfs-cache-max-age 4h \
        --vfs-read-ahead 64M \
        --buffer-size 16M \
        --dir-cache-time 72h \
        --use-mmap
      '';

      ExecStop = "${pkgs.util-linux}/bin/umount -l /data";

      Restart = "on-failure";
      RestartSec = "30s";

      TimeoutStopSec = "60s";
    };
  };
}

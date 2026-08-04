{ lib, pkgs, ... }:
let
  user = "u489674";
  host = "u489674.your-storagebox.de";
  port = 23;
  key = "/root/.ssh/root@megumu";
  cache = "/var/cache/rclone";
in {
  programs.ssh.knownHosts = {
    storagebox-rsa = {
      hostNames = [ "[${host}]:${toString port}" ];
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
    };
    storagebox-ecdsa = {
      hostNames = [ "[${host}]:${toString port}" ];
      publicKey = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";
    };
    storagebox-ed25519 = {
      hostNames = [ "[${host}]:${toString port}" ];
      publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
    };
  };

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

    path = [ "/run/wrappers" pkgs.getent ];

    preStart = ''
      ${pkgs.util-linux}/bin/umount -l /data 2>/dev/null || true
      mkdir -p /data
      mkdir -p ${cache}

      attempt=1
      while [ "$attempt" -le 60 ]; do
        if ${lib.getExe pkgs.getent} ahostsv4 ${host} >/dev/null; then
          exit 0
        fi

        echo "Waiting for DNS to resolve ${host} ($attempt/60)"
        ${pkgs.coreutils}/bin/sleep 1
        attempt=$((attempt + 1))
      done

      echo "DNS never resolved ${host}" >&2
      exit 1
    '';

    serviceConfig = {
      Type = "notify";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount :sftp:megumu /data \
        --sftp-user ${user} \
        --sftp-host ${host} \
        --sftp-port ${toString port} \
        --sftp-key-file ${key} \
        --sftp-known-hosts-file /etc/ssh/ssh_known_hosts \
        --allow-other \
        --allow-non-empty \
        --cache-dir ${cache} \
        --vfs-cache-mode full \
        --vfs-cache-max-size 5G \
        --vfs-cache-max-age 4h \
        --vfs-cache-min-free-space 10G \
        --vfs-read-ahead 64M \
        --buffer-size 4M \
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

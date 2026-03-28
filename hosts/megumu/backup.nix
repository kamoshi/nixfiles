{ config, ... }:
let
  pathBackup = "/var/backup/postgres";
in
{
  sops.secrets."restic" = {
    mode = "0600";
  };

  services.postgresql = {
    enable = true;
  };

  systemd.tmpfiles.rules = [
    "d ${pathBackup} 0700 postgres postgres -"
  ];

  services.postgresqlBackup = {
    enable = true;
    # Add database names in modules
    databases = [ ];
    location = pathBackup;
    startAt = "*-*-* 02:00:00";
  };

  services.restic.backups = {
    daily = {
      # Add paths in modules
      paths = [
        pathBackup
      ];
      repository = "/data/backup/megumu";
      initialize = true;
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
      passwordFile = config.sops.secrets."restic".path;
      timerConfig = {
        OnCalendar = "04:00";
        Persistent = true;
      };
    };
  };

  # Restic backs up to /data which is the storagebox FUSE mount
  systemd.services.restic-backups-daily = {
    requires = [ "storagebox.service" ];
    after = [ "storagebox.service" ];
  };
}

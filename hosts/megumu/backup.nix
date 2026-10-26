{ config, ... }:
let
  pathBackup = "/var/backup/postgres";
  resticRepository = "/data/backup/megumu";
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
    "d ${resticRepository} 0700 root root -"
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
      repository = resticRepository;
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

}

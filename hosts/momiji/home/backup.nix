{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = config.home.homeDirectory;
  repository = "/data/Backups/restic-momiji";
  sources = [
    "${home}/Documents"
    "${home}/Pictures"
    "${home}/Videos"
  ];
  cloudRepository = "sftp:u489674-sub1@u489674-sub1.your-storagebox.de:restic-momiji-kamov";
  backupLock = "%t/restic-backup-momiji.lock";

  storageboxSftp = pkgs.writeShellApplication {
    name = "storagebox-backup-sftp";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      exec ssh \
        -p 23 \
        -i ${lib.escapeShellArg "${home}/.ssh/kamov"} \
        -o IdentitiesOnly=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o ServerAliveInterval=60 \
        -o ServerAliveCountMax=240 \
        u489674-sub1@u489674-sub1.your-storagebox.de \
        -s sftp
    '';
  };

  runBackup = ''
    export RESTIC_PASSWORD_FILE="''${RESTIC_PASSWORD_FILE:-${config.sops.secrets.restic-repo-momiji-ssd.path}}"
    export RESTIC_CACHE_DIR="''${RESTIC_CACHE_DIR:-${config.xdg.cacheHome}/restic}"

    mkdir -p "$RESTIC_CACHE_DIR"

    restic_command backup ${lib.escapeShellArgs sources}
    restic_command forget --prune \
      --keep-weekly 8 \
      --keep-monthly 12 \
      --keep-yearly 3

    if (( check_repository )); then
      restic_command check
    fi
  '';

  backupToDir = pkgs.writeShellApplication {
    name = "backup-to-dir";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.restic
      pkgs.util-linux
    ];
    text = ''
      check_repository=0
      if [[ "''${1:-}" == "--check" ]]; then
        check_repository=1
        shift
      fi

      if (( $# != 1 )); then
        echo "Usage: backup-to-dir [--check] DIRECTORY" >&2
        exit 2
      fi

      RESTIC_REPOSITORY=$(realpath -m -- "$1")
      export RESTIC_REPOSITORY

      restic_command() {
        restic "$@"
      }

      if [[ "$RESTIC_REPOSITORY" == /data/* ]] && ! mountpoint --quiet /data; then
        echo "Refusing to back up: /data is not mounted" >&2
        exit 1
      fi

      for source in ${lib.escapeShellArgs sources}; do
        if [[ "$RESTIC_REPOSITORY" == "$source" || "$RESTIC_REPOSITORY" == "$source"/* ]]; then
          echo "Refusing to place the repository inside backup source: $source" >&2
          exit 2
        fi
      done

      mkdir -p "$(dirname "$RESTIC_REPOSITORY")"

      if [[ ! -e "$RESTIC_REPOSITORY/config" ]]; then
        restic_command init
      fi

      ${runBackup}
    '';
  };

  backupToSsd = pkgs.writeShellApplication {
    name = "backup-to-ssd";
    runtimeInputs = [ backupToDir ];
    text = ''
      check_option=()
      if [[ "''${1:-}" == "--check" ]]; then
        check_option=(--check)
        shift
      fi

      if (( $# != 0 )); then
        echo "Usage: backup-to-ssd [--check]" >&2
        exit 2
      fi

      exec backup-to-dir "''${check_option[@]}" ${lib.escapeShellArg repository}
    '';
  };

  backupToCloud = pkgs.writeShellApplication {
    name = "backup-to-cloud";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.openssh
      pkgs.restic
    ];
    text = ''
      check_repository=0

      while (( $# > 0 )); do
        case "$1" in
          --check)
            check_repository=1
            ;;
          *)
            echo "Usage: backup-to-cloud [--check]" >&2
            exit 2
            ;;
        esac
        shift
      done

      export RESTIC_REPOSITORY=${lib.escapeShellArg cloudRepository}
      export RESTIC_PASSWORD_FILE=${lib.escapeShellArg config.sops.secrets.restic-repo-momiji-cloud.path}
      export RESTIC_CACHE_DIR="''${RESTIC_CACHE_DIR:-${config.xdg.cacheHome}/restic}"

      restic_command() {
        restic -o ${lib.escapeShellArg "sftp.command=${lib.getExe storageboxSftp}"} "$@"
      }

      if ! restic_command cat config >/dev/null; then
        echo "Cloud repository is unavailable; initialize it locally and rsync it first" >&2
        exit 1
      fi

      ${runBackup}
    '';
  };

  checkSsdRepository = pkgs.writeShellApplication {
    name = "check-ssd-repository";
    runtimeInputs = [
      pkgs.restic
      pkgs.util-linux
    ];
    text = ''
      if ! mountpoint --quiet /data; then
        echo "Refusing to check repository: /data is not mounted" >&2
        exit 1
      fi

      export RESTIC_PASSWORD_FILE=${lib.escapeShellArg config.sops.secrets.restic-repo-momiji-ssd.path}
      export RESTIC_CACHE_DIR=${lib.escapeShellArg "${config.xdg.cacheHome}/restic"}

      exec restic --repo ${lib.escapeShellArg repository} check "$@"
    '';
  };

  checkCloudRepository = pkgs.writeShellApplication {
    name = "check-cloud-repository";
    runtimeInputs = [ pkgs.restic ];
    text = ''
      export RESTIC_PASSWORD_FILE=${lib.escapeShellArg config.sops.secrets.restic-repo-momiji-cloud.path}
      export RESTIC_CACHE_DIR=${lib.escapeShellArg "${config.xdg.cacheHome}/restic"}

      exec restic \
        -o ${lib.escapeShellArg "sftp.command=${lib.getExe storageboxSftp}"} \
        --repo ${lib.escapeShellArg cloudRepository} \
        check "$@"
    '';
  };

  notifyBackupResult = pkgs.writeShellApplication {
    name = "notify-restic-result";
    runtimeInputs = [ pkgs.libnotify ];
    text = ''
      if (( $# != 2 )); then
        echo "Usage: notify-restic-result success|failure SYSTEMD_UNIT" >&2
        exit 2
      fi

      status=$1
      unit=$2

      case "$status" in
        success)
          urgency=normal
          icon=emblem-default
          title="Restic task succeeded"
          message="$unit completed successfully."
          ;;
        failure)
          urgency=critical
          icon=dialog-error
          title="Restic task failed"
          message="$unit failed. Inspect it with: journalctl --user -u $unit"
          ;;
        *)
          echo "Unknown result: $status" >&2
          exit 2
          ;;
      esac

      exec notify-send \
        --app-name="Restic backups" \
        --urgency="$urgency" \
        --icon="$icon" \
        --hint=string:desktop-entry:restic-backups \
        --hint=boolean:transient:false \
        "$title" \
        "$message"
    '';
  };

  resticMomiji = pkgs.writeShellApplication {
    name = "restic-momiji";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.restic
    ];
    text = ''
      if (( $# < 2 )); then
        echo "Usage: restic-momiji COMMAND REPOSITORY [ARGUMENTS...]" >&2
        exit 2
      fi

      command=$1
      repository=$(realpath -m -- "$2")
      shift 2

      export RESTIC_PASSWORD_FILE="''${RESTIC_PASSWORD_FILE:-${config.sops.secrets.restic-repo-momiji-ssd.path}}"
      export RESTIC_CACHE_DIR="''${RESTIC_CACHE_DIR:-${config.xdg.cacheHome}/restic}"

      exec restic --repo "$repository" "$command" "$@"
    '';
  };
in
{
  sops.secrets.restic-repo-momiji-ssd = {
    mode = "0400";
  };

  sops.secrets.restic-repo-momiji-cloud = {
    mode = "0400";
  };

  xdg.desktopEntries.restic-backups = {
    name = "Restic Backups";
    genericName = "Backup notifications";
    icon = "drive-harddisk";
    exec = "${pkgs.coreutils}/bin/true";
    noDisplay = true;
  };

  home.packages = [
    pkgs.restic
    backupToDir
    backupToSsd
    backupToCloud
    resticMomiji
  ];

  systemd.user.services.restic-backup-momiji = {
    Unit = {
      Description = "Back up personal files with Restic";
      OnFailure = [ "restic-backup-failure@%n.service" ];
      OnSuccess = [ "restic-backup-success@%n.service" ];
    };

    Service = {
      Type = "oneshot";
      Environment = [
        "RESTIC_REPOSITORY=${repository}"
        "RESTIC_PASSWORD_FILE=${config.sops.secrets.restic-repo-momiji-ssd.path}"
        "RESTIC_CACHE_DIR=${config.xdg.cacheHome}/restic"
      ];
      ExecStart = "${pkgs.util-linux}/bin/flock --exclusive ${backupLock} ${lib.getExe backupToSsd}";
      Nice = 10;
      IOSchedulingClass = "idle";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  systemd.user.timers.restic-backup-momiji = {
    Unit.Description = "Weekly Restic backup of personal files";

    Timer = {
      OnCalendar = "Fri *-*-* 12:00:00";
      Persistent = true;
      RandomizedDelaySec = "2h";
      Unit = "restic-backup-momiji.service";
    };

    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.restic-backup-momiji-cloud = {
    Unit = {
      Description = "Back up personal files to Storage Box with Restic";
      After = [ "restic-backup-momiji.service" ];
      OnFailure = [ "restic-backup-failure@%n.service" ];
      OnSuccess = [ "restic-backup-success@%n.service" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/flock --exclusive ${backupLock} ${lib.getExe backupToCloud}";
      Nice = 10;
      IOSchedulingClass = "idle";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  systemd.user.timers.restic-backup-momiji-cloud = {
    Unit.Description = "Weekly Restic backup of personal files to Storage Box";

    Timer = {
      OnCalendar = "Fri *-*-* 14:00:00";
      Persistent = true;
      RandomizedDelaySec = "2h";
      Unit = "restic-backup-momiji-cloud.service";
    };

    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services."restic-backup-failure@" = {
    Unit.Description = "Notify about failed Restic task %i";

    Service = {
      Type = "oneshot";
      Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus" ];
      ExecStart = "${lib.getExe notifyBackupResult} failure %i";
    };
  };

  systemd.user.services."restic-backup-success@" = {
    Unit.Description = "Notify about successful Restic task %i";

    Service = {
      Type = "oneshot";
      Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus" ];
      ExecStart = "${lib.getExe notifyBackupResult} success %i";
    };
  };

  systemd.user.services.restic-check-momiji-ssd-weekly = {
    Unit = {
      Description = "Check SSD Restic repository metadata";
      OnFailure = [ "restic-backup-failure@%n.service" ];
      OnSuccess = [ "restic-backup-success@%n.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/flock --exclusive ${backupLock} ${lib.getExe checkSsdRepository}";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  systemd.user.timers.restic-check-momiji-ssd-weekly = {
    Unit.Description = "Weekly SSD Restic repository metadata check";
    Timer = {
      OnCalendar = "Tue *-*-* 12:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.restic-check-momiji-cloud-weekly = {
    Unit = {
      Description = "Check Storage Box Restic repository metadata";
      OnFailure = [ "restic-backup-failure@%n.service" ];
      OnSuccess = [ "restic-backup-success@%n.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/flock --exclusive ${backupLock} ${lib.getExe checkCloudRepository}";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  systemd.user.timers.restic-check-momiji-cloud-weekly = {
    Unit.Description = "Weekly Storage Box Restic repository metadata check";
    Timer = {
      OnCalendar = "Tue *-*-* 14:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.restic-check-momiji-ssd-monthly = {
    Unit = {
      Description = "Fully verify data in SSD Restic repository";
      OnFailure = [ "restic-backup-failure@%n.service" ];
      OnSuccess = [ "restic-backup-success@%n.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/flock --exclusive ${backupLock} ${lib.getExe checkSsdRepository} --read-data";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  systemd.user.timers.restic-check-momiji-ssd-monthly = {
    Unit.Description = "Monthly full SSD Restic repository data check";
    Timer = {
      OnCalendar = "Wed *-*-01..07 12:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.restic-check-momiji-cloud-monthly = {
    Unit = {
      Description = "Verify a monthly data subset in Storage Box Restic repository";
      OnFailure = [ "restic-backup-failure@%n.service" ];
      OnSuccess = [ "restic-backup-success@%n.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/flock --exclusive ${backupLock} ${lib.getExe checkCloudRepository} --read-data-subset=10%%";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  systemd.user.timers.restic-check-momiji-cloud-monthly = {
    Unit.Description = "Monthly Storage Box Restic repository data-subset check";
    Timer = {
      OnCalendar = "Wed *-*-01..07 14:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}

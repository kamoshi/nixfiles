{
  config,
  lib,
  rolling,
  pkgs,
  ...
}:
let
  inherit (config.home) homeDirectory;

  backupSources = [
    "${homeDirectory}/Documents"
    "${homeDirectory}/Pictures"
    "${homeDirectory}/Videos"
  ];

  ssdRepository = "/data/Backups/restic-momiji";
  cloudRepository = "sftp:u489674-sub1@u489674-sub1.your-storagebox.de:restic-momiji-kamov";
  ssdPasswordFile = config.sops.secrets.restic-repo-momiji-ssd.path;
  cloudPasswordFile = config.sops.secrets.restic-repo-momiji-cloud.path;
  resticCacheDirectory = "${config.xdg.cacheHome}/restic";

  taskLock = "restic-backup-momiji.lock";
  taskStateDirectory = "restic-momiji";
  taskStatePath = "${config.xdg.stateHome}/${taskStateDirectory}";

  storageboxSftp = pkgs.writeShellApplication {
    name = "storagebox-backup-sftp";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      exec ssh \
        -F none \
        -p 23 \
        -i ${lib.escapeShellArg "${homeDirectory}/.ssh/kamov"} \
        -o IdentitiesOnly=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o ServerAliveInterval=60 \
        -o ServerAliveCountMax=240 \
        u489674-sub1@u489674-sub1.your-storagebox.de \
        -s sftp
    '';
  };

  mkResticWrapper =
    {
      name,
      repository,
      passwordFile,
      extraOptions ? [ ],
      runtimeInputs ? [ ],
      preflight ? "",
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.coreutils
        rolling.restic
      ]
      ++ runtimeInputs;
      text = ''
        export RESTIC_PASSWORD_FILE=${lib.escapeShellArg passwordFile}
        export RESTIC_CACHE_DIR="''${RESTIC_CACHE_DIR:-${resticCacheDirectory}}"
        mkdir -p "$RESTIC_CACHE_DIR"

        ${preflight}

        exec restic \
          ${lib.escapeShellArgs extraOptions} \
          --repo ${lib.escapeShellArg repository} \
          "$@"
      '';
    };

  resticSsd = mkResticWrapper {
    name = "restic-ssd";
    repository = ssdRepository;
    passwordFile = ssdPasswordFile;
    runtimeInputs = [ pkgs.util-linux ];
    preflight = ''
      if ! mountpoint --quiet /data; then
        echo "Refusing to access the SSD repository: /data is not mounted" >&2
        exit 1
      fi
    '';
  };

  resticCloud = mkResticWrapper {
    name = "restic-cloud";
    repository = cloudRepository;
    passwordFile = cloudPasswordFile;
    extraOptions = [
      "-o"
      "sftp.command=${lib.getExe storageboxSftp}"
    ];
  };

  parseCheckOption = usage: ''
    check_repository=0

    if [[ "''${1:-}" == "--check" ]]; then
      check_repository=1
      shift
    fi

    if (( $# != 0 )); then
      echo ${lib.escapeShellArg "Usage: ${usage}"} >&2
      exit 2
    fi
  '';

  runBackup = resticCommand: ''
    ${resticCommand} backup ${lib.escapeShellArgs backupSources}
    ${resticCommand} forget --prune \
      --keep-weekly 8 \
      --keep-monthly 12 \
      --keep-yearly 3

    if (( check_repository )); then
      ${resticCommand} check
    fi
  '';

  backupToPath = pkgs.writeShellApplication {
    name = "backup-to-path";
    runtimeInputs = [
      pkgs.coreutils
      rolling.restic
      pkgs.util-linux
    ];
    text = ''
      check_repository=0
      if [[ "''${1:-}" == "--check" ]]; then
        check_repository=1
        shift
      fi

      if (( $# != 1 )); then
        echo "Usage: backup-to-path [--check] PATH" >&2
        exit 2
      fi

      repository=$(realpath -m -- "$1")

      if [[ "$repository" == /data/* ]] && ! mountpoint --quiet /data; then
        echo "Refusing to back up: /data is not mounted" >&2
        exit 1
      fi

      for source in ${lib.escapeShellArgs backupSources}; do
        if [[ "$repository" == "$source" || "$repository" == "$source"/* ]]; then
          echo "Refusing to place the repository inside backup source: $source" >&2
          exit 2
        fi
      done

      export RESTIC_REPOSITORY="$repository"
      export RESTIC_PASSWORD_FILE="''${RESTIC_PASSWORD_FILE:-${ssdPasswordFile}}"
      export RESTIC_CACHE_DIR="''${RESTIC_CACHE_DIR:-${resticCacheDirectory}}"

      mkdir -p "$RESTIC_CACHE_DIR" "$(dirname "$repository")"

      if [[ ! -e "$repository/config" ]]; then
        restic init
      fi

      ${runBackup "restic"}
    '';
  };

  backupToSsd = pkgs.writeShellApplication {
    name = "backup-to-ssd";
    runtimeInputs = [ backupToPath ];
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

      exec backup-to-path "''${check_option[@]}" ${lib.escapeShellArg ssdRepository}
    '';
  };

  backupToCloud = pkgs.writeShellApplication {
    name = "backup-to-cloud";
    runtimeInputs = [ resticCloud ];
    text = ''
      ${parseCheckOption "backup-to-cloud [--check]"}

      if ! restic-cloud cat config >/dev/null; then
        echo "Cloud repository is unavailable; initialize it locally and sync it first" >&2
        exit 1
      fi

      ${runBackup "restic-cloud"}
    '';
  };

  notifyTaskResult = pkgs.writeShellApplication {
    name = "notify-restic-result";
    runtimeInputs = [ pkgs.libnotify ];
    text = ''
      if (( $# != 2 )); then
        echo "Usage: notify-restic-result success|failure SYSTEMD_UNIT" >&2
        exit 2
      fi

      status=$1
      unit=$2

      case "$unit" in
        restic-backup-momiji.service)
          task="SSD backup"
          ;;
        restic-backup-momiji-cloud.service)
          task="Cloud backup"
          ;;
        restic-check-momiji-ssd-*.service)
          task="SSD repository check"
          ;;
        restic-check-momiji-cloud-*.service)
          task="Cloud repository check"
          ;;
        *)
          task="$unit"
          ;;
      esac

      case "$status" in
        success)
          urgency=normal
          icon=emblem-default
          title="$task succeeded"
          message="$unit completed successfully."
          ;;
        failure)
          urgency=critical
          icon=dialog-error
          title="$task failed"
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
        --expire-time=0 \
        --icon="$icon" \
        --hint=string:desktop-entry:restic-backups \
        --hint=boolean:transient:false \
        --hint=boolean:resident:true \
        "$title" \
        "$message"
    '';
  };

  taskDefinitions = {
    restic-backup-momiji = {
      description = "Back up personal files to the SSD";
      command = [ (lib.getExe backupToSsd) ];
      marker = "backup-ssd";
      calendar = "Fri *-*-* 12:00:00";
      randomizedDelay = "2h";
    };

    restic-backup-momiji-cloud = {
      description = "Back up personal files to Storage Box";
      command = [ (lib.getExe backupToCloud) ];
      marker = "backup-cloud";
      calendar = "Fri *-*-* 14:00:00";
      randomizedDelay = "2h";
      after = [ "restic-backup-momiji.service" ];
    };

    restic-check-momiji-ssd-weekly = {
      description = "Check SSD repository metadata";
      command = [
        (lib.getExe resticSsd)
        "check"
      ];
      marker = "check-ssd-weekly";
      calendar = "Tue *-*-* 12:00:00";
      randomizedDelay = "1h";
    };

    restic-check-momiji-cloud-weekly = {
      description = "Check Storage Box repository metadata";
      command = [
        (lib.getExe resticCloud)
        "check"
      ];
      marker = "check-cloud-weekly";
      calendar = "Tue *-*-* 14:00:00";
      randomizedDelay = "1h";
    };

    restic-check-momiji-ssd-monthly = {
      description = "Fully verify the SSD repository";
      command = [
        (lib.getExe resticSsd)
        "check"
        "--read-data"
      ];
      marker = "check-ssd-monthly";
      calendar = "Wed *-*-01..07 12:00:00";
      randomizedDelay = "1h";
    };

    restic-check-momiji-cloud-monthly = {
      description = "Verify a data subset in the Storage Box repository";
      command = [
        (lib.getExe resticCloud)
        "check"
        "--read-data-subset=10%"
      ];
      marker = "check-cloud-monthly";
      calendar = "Wed *-*-01..07 14:00:00";
      randomizedDelay = "1h";
    };
  };

  mkTaskRunner =
    name: task:
    let
      markerPath = "${taskStatePath}/${task.marker}";
    in
    pkgs.writeShellApplication {
      name = "${name}-runner";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.util-linux
      ];
      text = ''
        readonly max_attempts=4
        readonly retry_delay=15m
        readonly lock_file="''${XDG_RUNTIME_DIR:?}/${taskLock}"

        # Preserve the marker when systemd interrupts us during shutdown.
        trap 'exit 143' HUP INT TERM

        for (( attempt = 1; attempt <= max_attempts; attempt++ )); do
          if flock --exclusive "$lock_file" ${lib.escapeShellArgs task.command}; then
            exit 0
          else
            status=$?
          fi

          if (( attempt == max_attempts )); then
            break
          fi

          echo "Attempt $attempt/$max_attempts failed; retrying in $retry_delay" >&2
          sleep "$retry_delay"
        done

        # The task completed with an ordinary failure, so it must not be
        # mistaken for an interruption and resumed at the next login.
        rm -f ${lib.escapeShellArg markerPath}
        exit "$status"
      '';
    };

  mkTaskService =
    name: task:
    let
      markerPath = "${taskStatePath}/${task.marker}";
      runner = mkTaskRunner name task;
    in
    {
      Unit = {
        Description = task.description;
        After = task.after or [ ];
        OnFailure = [ "restic-backup-failure@%n.service" ];
        OnSuccess = [ "restic-backup-success@%n.service" ];
      };

      Service = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/touch ${lib.escapeShellArg markerPath}";
        ExecStart = lib.getExe runner;
        ExecStartPost = "${pkgs.coreutils}/bin/rm -f ${lib.escapeShellArg markerPath}";
        StateDirectory = taskStateDirectory;
        Nice = 10;
        IOSchedulingClass = "idle";
        NoNewPrivileges = true;
        PrivateTmp = true;
        X-RestartIfChanged = false;
      };
    };

  mkRecoveryService = name: task: {
    Unit = {
      Description = "Resume interrupted ${task.description}";
      ConditionPathExists = "${taskStatePath}/${task.marker}";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user start --no-block ${name}.service";
      X-RestartIfChanged = false;
    };
    Install.WantedBy = [ "default.target" ];
  };

  mkTaskTimer = task: {
    Unit.Description = "Schedule: ${task.description}";
    Timer = {
      OnCalendar = task.calendar;
      Persistent = true;
      RandomizedDelaySec = task.randomizedDelay;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  taskServices = lib.mapAttrs mkTaskService taskDefinitions;
  recoveryServices = lib.mapAttrs' (
    name: task: lib.nameValuePair "restic-recover-${name}" (mkRecoveryService name task)
  ) taskDefinitions;
  taskTimers = lib.mapAttrs (_: task: mkTaskTimer task) taskDefinitions;
in
{
  sops.secrets = {
    restic-repo-momiji-ssd.mode = "0400";
    restic-repo-momiji-cloud.mode = "0400";
  };

  xdg.desktopEntries.restic-backups = {
    name = "Restic Backups";
    genericName = "Backup notifications";
    icon = "drive-harddisk";
    exec = "${pkgs.coreutils}/bin/true";
    noDisplay = true;
  };

  home.packages = [
    rolling.restic
    resticSsd
    resticCloud
    backupToPath
    backupToSsd
    backupToCloud
  ];

  systemd.user.services =
    taskServices
    // recoveryServices
    // {
      "restic-backup-failure@" = {
        Unit.Description = "Notify about failed Restic task %i";
        Service = {
          Type = "oneshot";
          Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus" ];
          ExecStart = "${lib.getExe notifyTaskResult} failure %i";
        };
      };

      "restic-backup-success@" = {
        Unit.Description = "Notify about successful Restic task %i";
        Service = {
          Type = "oneshot";
          Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus" ];
          ExecStart = "${lib.getExe notifyTaskResult} success %i";
        };
      };
    };

  systemd.user.timers = taskTimers;
}

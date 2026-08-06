{ ... }:
let
  domain = "photos.internal";
  bind = "127.0.0.1";
  port = 2283;
  photos = "/srv/storagebox/crypt/photos";
in
{
  services.immich = {
    enable = true;
    host = bind;
    port = port;
    openFirewall = false;

    settings = {
      server.externalDomain = "https://${domain}";

      # Force sequential job execution to prevent resource starvation
      job = {
        backgroundTask.concurrency = 1;
        thumbnailGeneration.concurrency = 1;
        metadataExtraction.concurrency = 1;
        videoConversion.concurrency = 1;
        faceDetection.concurrency = 1;
        smartSearch.concurrency = 1;
        library.concurrency = 1;
        migration.concurrency = 1;
        sidecar.concurrency = 1;
      };

      # Limit video transcoding to a single thread
      ffmpeg.threads = 1;
    };

    # Keep the initial deployment small. This can be enabled later for face
    # recognition and semantic search.
    machine-learning.enable = false;
  };

  systemd.services.immich-server = {
    # Immich must never start against the empty directory hidden beneath the
    # rclone mount, and should stop if the mount disappears.
    bindsTo = [ "storagebox_enc.service" ];
    after = [ "storagebox_enc.service" ];

    # Immich may index this external library but cannot modify its source
    # photos or create XMP sidecars there.
    serviceConfig = {
      BindReadOnlyPaths = [ photos ];

      # Protect system stability by leaving ~25% of the 1 vCPU core free
      CPUQuota = "75%";

      # Apply memory pressure here, with a firm safety boundary above it.
      MemoryHigh = "2G";
      MemoryMax = "2500M";
    };
  };

  services.postgresqlBackup.databases = [ "immich" ];
  # services.restic.backups.daily.paths = [ "/var/lib/immich" ];

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    bind 10.0.0.1
    tls internal
    reverse_proxy ${bind}:${toString port}
  '';

  services.blocky.settings.customDNS.mapping.${domain} = "10.0.0.1";
}

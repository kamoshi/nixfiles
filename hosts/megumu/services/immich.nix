{ device, inventory, nightly, ... }:
let
  endpoint = inventory.endpoints.immich;
  proxyBind = "127.0.0.1";
  photos = "/srv/storagebox/crypt/photos";
in
{
  services.immich = {
    enable = true;
    host = endpoint.bind;
    port = endpoint.port;
    openFirewall = false;

    settings = {
      # Generate share links for the public proxy while keeping the Immich UI
      # itself available only through the internal domain below.
      server.externalDomain = "https://${endpoint.domains.external}";

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
  services.restic.backups.daily.paths = [ "/var/lib/immich" ];

  services.caddy.virtualHosts.${endpoint.domains.internal}.extraConfig = ''
    bind ${device.vpn.ip}
    tls internal
    reverse_proxy ${endpoint.bind}:${toString endpoint.port}
  '';

  services.blocky.settings.customDNS.mapping.${endpoint.domains.internal} = device.vpn.ip;

  services.immich-public-proxy = {
    enable = true;
    package = nightly.immich-public-proxy;
    immichUrl = "http://${endpoint.bind}:${toString endpoint.port}";
    port = endpoint.proxyPort;
    openFirewall = false;

    settings.ipp = {
      # Keep download permissions under the control of each Immich share.
      allowDownload = 1;
      maxDownloadQuality = "original";
      downloadedFilename = 0;

      # Avoid overwhelming this host while assembling a large ZIP archive.
      downloadFromImmichConcurrencyLimit = 2;

      gallery = {
        # A direct image response has no metadata or download controls.
        singleImage = true;
        singleItemAutoOpen = true;
      };

      lightbox.showDownload = true;

      # IPP still suppresses all of these unless "Show metadata" is enabled
      # on the individual share in Immich.
      showMetadata = {
        description = {
          caption = false;
          sidebar = true;
        };

        exif = {
          dateTimeOriginal = true;
          fileName = true;
          dimensions = true;
          fileSize = true;
          make = true;
          model = true;
          lensModel = true;
          exposureTime = true;
          iso = true;
          fNumber = true;
          focalLength = true;
        };

        location = {
          city = true;
          state = true;
          country = true;
          gps = false;
        };
      };
    };
  };

  systemd.services.immich-public-proxy = {
    requires = [ "immich-server.service" ];
    after = [ "immich-server.service" ];

    # The public proxy only needs loopback access to Immich and nginx. Keep it
    # isolated even if firewall rules change.
    serviceConfig = {
      IPAddressDeny = "any";
      IPAddressAllow = "localhost";
    };
  };

  services.nginx.virtualHosts.${endpoint.domains.external} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://${proxyBind}:${toString endpoint.proxyPort}";
    };
  };
}

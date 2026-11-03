{ rolling, ... }:
{
  networking.hosts."10.0.0.5" = [ "photos.internal" ];

  services.blocky = {
    settings.customDNS.mapping."photos.internal" = "10.0.0.5";
  };

  services.immich-public-proxy = {
    enable = true;
    package = rolling.immich-public-proxy;
    immichUrl = "https://photos.internal";
    port = 9988;
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

  systemd.services = {
    # The public proxy needs loopback for its listener and the m920x WireGuard
    # address for Immich. Keep all other network access blocked.
    immich-public-proxy.serviceConfig = {
      # Nginx on loopback and Immich over WireGuard only.
      IPAddressDeny = "any";
      IPAddressAllow = [
        "localhost"
        "10.0.0.5/32"
      ];

      # Privilege restrictions
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";

      # Filesystem and process isolation
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateTmp = true;
      PrivateDevices = true;
      PrivateUsers = true;

      # Kernel and execution restrictions
      RestrictSUIDSGID = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
      ];

      # Restrict socket types
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
    };
  };

  services.nginx.virtualHosts."photos.kamoshi.org" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:9988";
    };
  };
}

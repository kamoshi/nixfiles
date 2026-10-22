{ device, inventory, rolling, ... }:
let
  endpoint = inventory.endpoints.immich;
  proxyBind = "127.0.0.1";
in
{
  # Keep backups of the old Megumu database and upload directory while the
  # active Immich instance runs on m920x.
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
    package = rolling.immich-public-proxy;
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
    # The public proxy needs loopback for its listener and the m920x WireGuard
    # address for Immich. Keep all other network access blocked.
    serviceConfig = {
      IPAddressDeny = "any";
      IPAddressAllow = [ "localhost" endpoint.bind ];
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

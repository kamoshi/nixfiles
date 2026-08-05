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
    settings.server.externalDomain = "https://${domain}";

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
    serviceConfig.BindReadOnlyPaths = [ photos ];
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

{ rolling, ... }:
let
  photos = "/data/photo";
in
{
  services.immich = {
    enable = true;
    package = rolling.immich;
    host = "127.0.0.1";
    port = 2283;
    openFirewall = false;

    settings.server.externalDomain = "https://photos.kamoshi.org";

    # Keep Immich's background work within this small host's resources.
    machine-learning.enable = false;
  };

  # Only kamov and the Immich service group can traverse this library.
  systemd.tmpfiles.rules = [
    "d ${photos} 2750 kamov immich -"
    "z ${photos} 2750 kamov immich -"
  ];

  # This is an external library: Immich can index and read photos, but cannot
  # alter originals or write sidecars into the source directory.
  systemd.services.immich-server.serviceConfig.BindReadOnlyPaths = [ photos ];
}

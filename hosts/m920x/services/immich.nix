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
    accelerationDevices = [ "/dev/dri/renderD128" ];

    settings = {
      server.externalDomain = "https://photos.kamoshi.org";

      ffmpeg = {
        transcode = "disabled";
        accel = "vaapi";
        accelDecode = true;
      };

      machineLearning = {
        enabled = true;
        clip.enabled = true;
        duplicateDetection.enabled = false;
        facialRecognition.enabled = false;
        ocr.enabled = false;
      };
    };

    machine-learning.enable = true;
  };

  systemd.tmpfiles.rules = [
    "d ${photos} 2750 kamov immich -"
    "z ${photos} 2750 kamov immich -"
  ];

  systemd.services = {
    # This is an external library: Immich can index and read photos, but cannot
    # alter originals or write sidecars into the source directory.
    immich-server.serviceConfig = {
      BindReadOnlyPaths = [ photos ];
      ProtectSystem = "strict";
      ProtectProc = "invisible";
      RemoveIPC = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
    };
  };

  services.blocky = {
    settings.customDNS.mapping."photos.internal" = "10.1.0.1";
  };

  services.caddy = {
    enable = true;

    virtualHosts."photos.internal".extraConfig = ''
      bind 10.1.0.1 10.0.0.5
      tls internal
      reverse_proxy localhost:2283
    '';
  };
}

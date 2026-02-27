{ pkgs, ... }:
let
  domain = "calibre.internal";
  bind = "10.0.0.1";
  port = 9998;
in {
  services.calibre-web = {
    enable = true;

    # FIXME: temporary override
    package = pkgs.calibre-web.overrideAttrs (old: rec {
      version = "0.6.26";
      src = pkgs.fetchFromGitHub {
        owner = "janeczku";
        repo = "calibre-web";
        rev = version;
        hash = "sha256-UlM6GmOSm1HyfQWvar3WCDCDAhyQcu1HNALk0E4hW5s=";
      };
    });

    listen.ip = bind;
    listen.port = port;
    options = {
      calibreLibrary = "/data/sync/calibre";
      enableBookUploading = false;
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts.${domain}.extraConfig = ''
      bind 10.0.0.1
      tls internal
      reverse_proxy ${bind}:${toString port}
    '';
  };

  services.blocky = {
    settings.customDNS.mapping.${domain} = "10.0.0.1";
  };
}

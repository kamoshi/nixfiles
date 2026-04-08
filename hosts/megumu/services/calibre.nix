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
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        pkgs.python3Packages.pythonRelaxDepsHook
      ];
      # nixpkgs currently ships wand 0.7.0 while 0.6.26 still declares <0.7.0.
      pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "wand" ];
    });

    listen.ip = bind;
    listen.port = port;
    options = {
      calibreLibrary = "/data/sync/calibre";
      enableBookUploading = false;
    };
  };

  systemd.services.calibre-web = {
    # Force Calibre to wait until /data is actually mounted,
    # and stop it immediately if storagebox unmounts (e.g. during nixos-rebuild)
    bindsTo = [ "storagebox.service" ];
    after = [ "storagebox.service" ];
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

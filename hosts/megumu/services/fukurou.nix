{
  config,
  device,
  fukurouSrc,
  inventory,
  lib,
  pkgs,
  ...
}:
let
  endpoint = inventory.endpoints.fukurou;
  package = pkgs.rustPlatform.buildRustPackage {
    pname = "fukurou";
    version = "0.1.0";
    src = fukurouSrc;

    cargoLock.lockFile = "${fukurouSrc}/Cargo.lock";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.sqlite ];
  };
in
{
  sops.secrets.kotori = {
    mode = "0400";
  };

  services.fukurou = {
    enable = true;
    port = endpoint.port;
    portInternal = endpoint.internalPort;
    envFile = config.sops.secrets.kotori.path;
  };

  systemd.services.fukurou.serviceConfig.ExecStart = lib.mkForce "${package}/bin/fukurou";

  services.caddy = {
    enable = true;
    virtualHosts.${endpoint.domains.internal}.extraConfig = ''
      bind ${device.vpn.ip}
      tls internal
      reverse_proxy ${endpoint.bind}:${toString endpoint.internalPort}
    '';
  };

  services.blocky = {
    settings.customDNS.mapping.${endpoint.domains.internal} = device.vpn.ip;
  };

  services.nginx = {
    enable = true;

    virtualHosts.${endpoint.domains.external} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://${endpoint.bind}:${toString endpoint.port}";
      };
    };
  };
}

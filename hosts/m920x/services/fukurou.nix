{
  config,
  inventory,
  ...
}:
let
  endpoint = inventory.endpoints.fukurou;
in
{
  sops.secrets.fukurou.mode = "0400";

  services.fukurou = {
    enable = true;
    port = endpoint.port;
    portInternal = endpoint.internalPort;
    envFile = config.sops.secrets.fukurou.path;
  };

  networking.firewall.interfaces.gensokyo.allowedTCPPorts = [
    endpoint.port
    endpoint.internalPort
  ];
}

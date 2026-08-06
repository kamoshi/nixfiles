{ inventory, ... }:
let
  endpoint = inventory.endpoints.woodpecker;
in
{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  services.woodpecker-server = {
    enable = true;
    environment = {
      WOODPECKER_HOST = "https://${endpoint.domains.external}";
      WOODPECKER_SERVER_ADDR = "${endpoint.bind}:${toString endpoint.port}";
      WOODPECKER_OPEN = "false";
    };
  };

  services.woodpecker-agents.agents."local" = {
    enable = true;
    environment = {
      WOODPECKER_SERVER = "${endpoint.bind}:${toString endpoint.port}";
      WOODPECKER_BACKEND = "docker";
    };
    extraGroups = [ "podman" ];
  };

  # services.nginx.virtualHosts.${endpoint.domains.external} = {
  #   enableACME = true;
  #   forceSSL = true;
  #   locations."/" = {
  #     proxyPass = "http://${endpoint.bind}:${toString endpoint.port}";
  #     proxyWebsockets = true;
  #   };
  # };
}

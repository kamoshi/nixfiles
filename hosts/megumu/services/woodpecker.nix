{ ... }:
let
  port = 8000;
  bind = "127.0.0.1";
  domain = "ci.kamoshi.org";
in
{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  services.woodpecker-server = {
    enable = true;
    environment = {
      WOODPECKER_HOST = "https://${domain}";
      WOODPECKER_SERVER_ADDR = "${bind}:${toString port}";
      WOODPECKER_OPEN = "false";
    };
  };

  services.woodpecker-agents.agents."local" = {
    enable = true;
    environment = {
      WOODPECKER_SERVER = "127.0.0.1:${toString port}";
      WOODPECKER_BACKEND = "docker";
    };
    extraGroups = [ "podman" ];
  };

  # services.nginx.virtualHosts.${domain} = {
  #   enableACME = true;
  #   forceSSL = true;
  #   locations."/" = {
  #     proxyPass = "http://${bind}:${toString port}";
  #     proxyWebsockets = true;
  #   };
  # };
}

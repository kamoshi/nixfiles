{ pkgs, ... }:
let
  port = 11434;
in
{
  services.unbound.settings.server.local-data = [
    ''"llm.m920x.internal. 3600 IN CNAME m920x.internal."''
  ];

  services.caddy = {
    enable = true;

    virtualHosts."llm.m920x.internal".extraConfig = ''
      bind 10.1.0.1
      tls internal
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cpu;

    syncModels = true;
    loadModels = [
      "qwen2.5-coder:1.5b-base"
    ];

    # environmentVariables = {
    #   OLLAMA_IGPU_ENABLE = "1";
    # };

    host = "127.0.0.1";
    port = port;
  };
}

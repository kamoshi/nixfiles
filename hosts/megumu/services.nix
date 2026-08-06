{ config, inventory, lib, ... }:
let
  inherit (inventory) endpoints;
in
{
  # Syncthing
  # =========
  kamov.syncthing = {
    enable = true;
    bind = endpoints.syncthing.bind;
    port = endpoints.syncthing.port;
    domain = endpoints.syncthing.domains.internal;
    user = "kamov";
    configDir = "/home/kamov/.config/syncthing";
  };

  systemd.services.syncthing = {
    bindsTo = [
      "storagebox.service"
      "storagebox_enc.service"
    ];
    after = [
      "storagebox.service"
      "storagebox_enc.service"
    ];
  };

  # Kotori
  # ======
  # sops.secrets.kotori = {
  #   mode = "0400";
  # };

  # kamov.kotori = {
  #   enable = true;
  #   envPath = config.sops.secrets.kotori.path;
  # };

  # Kanidm
  # ======
  kamov.kanidm = {
    enable = true;
    bind = endpoints.kanidm.bind;
    port = endpoints.kanidm.port;
    domain = endpoints.kanidm.domains.external;
  };

  # Miniflux
  # ========
  sops.secrets."kanidm/miniflux" = lib.mkIf config.kamov.miniflux.enable {
    owner = "miniflux";
    group = "kanidm";
    mode = "0440";
  };

  kamov.miniflux = {
    enable = true;
    bind = endpoints.miniflux.bind;
    port = endpoints.miniflux.port;
    domain = endpoints.miniflux.domains.external;
    oauthSecretPath = config.sops.secrets."kanidm/miniflux".path;
  };

  # Forgejo
  # =====
  sops.secrets."kanidm/forgejo" = {
    owner = "git";
    group = "kanidm";
    mode = "0440";
  };

  kamov.forgejo = {
    enable = true;
    bind = endpoints.forgejo.bind;
    port = endpoints.forgejo.port;
    domain = endpoints.forgejo.domains.external;
    oauthSecretPath = config.sops.secrets."kanidm/forgejo".path;
  };

  # Gatus
  # =====
  kamov.gatus = {
    enable = false;
    bind = endpoints.gatus.bind;
    port = endpoints.gatus.port;
    domain = endpoints.gatus.domains.external;
  };

  # Grafana
  # =======
  # sops.secrets."grafana/secret_key" = lib.mkIf config.kamov.grafana.enable {
  #   owner = "grafana";
  #   group = "grafana";
  #   mode = "0400";
  # };

  # sops.secrets."grafana/client_secret" = lib.mkIf config.kamov.grafana.enable {
  #   owner = "grafana";
  #   group = "kanidm";
  #   mode = "0440";
  # };

  kamov.grafana = {
    enable = false;
    bind = endpoints.grafana.bind;
    port = endpoints.grafana.port;
    domain = endpoints.grafana.domains.external;
  };

  # Vikunja
  # =======
  kamov.vikunja = {
    enable = false;
    bind = endpoints.vikunja.bind;
    port = endpoints.vikunja.port;
    domain = endpoints.vikunja.domains.external;
  };
}

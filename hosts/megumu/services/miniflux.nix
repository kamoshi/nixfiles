{ config, inventory, ... }:
let
  endpoint = inventory.endpoints.miniflux;
  kanidmEndpoint = inventory.endpoints.kanidm;
  oauthSecretPath = config.sops.secrets."kanidm/miniflux".path;
in
{
  sops.secrets."kanidm/miniflux" = {
    owner = "miniflux";
    group = "kanidm";
    mode = "0440";
  };

  # System security
  # ----------
  users.groups.miniflux = { };
  users.users.miniflux = {
    isSystemUser = true;
    createHome = false;
    group = "miniflux";
  };

  systemd.services.miniflux.serviceConfig = {
    User = "miniflux";
    Group = "miniflux";
  };

  # Miniflux
  # ----------
  services.miniflux = {
    enable = true;
    config = {
      LISTEN_ADDR = "${endpoint.bind}:${toString endpoint.port}";
      BASE_URL = "https://${endpoint.domains.external}/";
      RUN_MIGRATIONS = 1;
      CREATE_ADMIN = 0;
      CLEANUP_ARCHIVE_UNREAD_DAYS = "-1";
      CLEANUP_ARCHIVE_READ_DAYS = "-1";

      # pooling
      POLLING_PARSING_ERROR_LIMIT = 0;
      POLLING_SCHEDULER = "entry_frequency";
      POLLING_FREQUENCY = 30;
      SCHEDULER_ENTRY_FREQUENCY_FACTOR = 2;
      SCHEDULER_ENTRY_FREQUENCY_MIN_INTERVAL = 60;
      SCHEDULER_ENTRY_FREQUENCY_MAX_INTERVAL = 1440;

      # OIDC
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_CLIENT_SECRET_FILE = oauthSecretPath;
      OAUTH2_REDIRECT_URL = "https://${endpoint.domains.external}/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://${kanidmEndpoint.domains.external}/oauth2/openid/miniflux";

      # Disable local auth
      DISABLE_LOCAL_AUTH = "true";
      OAUTH2_USER_CREATION = "true";
    };
  };

  services.kanidm.provision.systems.oauth2.miniflux = {
    displayName = "Miniflux";
    originUrl = "https://${endpoint.domains.external}/oauth2/oidc/callback";
    originLanding = "https://${endpoint.domains.external}/oauth2/oidc/redirect";
    basicSecretFile = oauthSecretPath;
    preferShortUsername = true;
    scopeMaps."miniflux.access" = [
      "openid"
      "profile"
      "email"
    ];
  };

  # Network
  # ----------
  services.nginx.virtualHosts.${endpoint.domains.external} = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://${endpoint.bind}:${toString endpoint.port}";
  };

  # Backup
  # ------
  services.postgresqlBackup.databases = [ "miniflux" ];

  # services.fail2ban.jails = {
  #   miniflux = ''
  #     enabled = true
  #     filter = miniflux
  #     port = http,https
  #   '';
  # };

  # environment.etc = {
  #   "fail2ban/filter.d/miniflux.conf".text = ''
  #     [Definition]
  #     failregex = ^.*msg="[^"]*(Incorrect|Invalid) username or password[^"]*".*client_ip=<ADDR>
  #     journalmatch = _SYSTEMD_UNIT=miniflux.service
  #   '';
  # };
}

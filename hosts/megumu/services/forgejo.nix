{ config, inventory, pkgs, lib, ... }:
let
  endpoint = inventory.endpoints.forgejo;
  kanidmEndpoint = inventory.endpoints.kanidm;
  oauthSecretPath = config.sops.secrets."kanidm/forgejo".path;
  user = "git";
  state = "/var/lib/forgejo";
in
{
  sops.secrets."kanidm/forgejo" = {
    owner = user;
    group = "kanidm";
    mode = "0440";
  };

  users = {
    users.${user} = {
      description = "Forgejo Service";
      home = state;
      group = user;
      useDefaultShell = true;
      isSystemUser = true;
    };
    groups.${user} = { };
  };

  services = {
    forgejo = {
      enable = true;
      package = pkgs.forgejo;
      inherit user;
      group = user;
      stateDir = state;
      # https://forgejo.org/docs/latest/admin/config-cheat-sheet/
      settings = {
        DEFAULT.APP_NAME = "Git";
        oauth2_client = {
          # Never use auto account linking with this, otherwise users cannot change
          # their new user name and they could potentially overtake other users accounts
          # by setting their email address to an existing account.
          # With "login" linking the user must choose a non-existing username first or login
          # with the existing account to link.
          ACCOUNT_LINKING = "login";
          USERNAME = "nickname";
          # This does not mean that you cannot register via oauth, but just that there should
          # be a confirmation dialog shown to the user before the account is actually created.
          # This dialog allows changing user name and email address before creating the account.
          ENABLE_AUTO_REGISTRATION = false;
          REGISTER_EMAIL_CONFIRM = false;
          # UPDATE_AVATAR = true;
        };
        repository.DEFAULT_PRIVATE = "private";
        server = {
          HTTP_PORT = endpoint.port;
          HTTP_ADDR = endpoint.bind;
          DOMAIN = endpoint.domains.external;
          ROOT_URL = "https://${endpoint.domains.external}/";
          LANDING_PAGE = "login";
        };
        service = {
          DISABLE_REGISTRATION = false;
          ALLOW_ONLY_INTERNAL_REGISTRATION = false;
          ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
          SHOW_REGISTRATION_BUTTON = false;
          REGISTER_EMAIL_CONFIRM = false;
          # Disable pasword login
          ENABLE_BASIC_AUTHENTICATION = false;
          ENABLE_INTERNAL_SIGNIN = false;
        };
        session.COOKIE_SECURE = true;
        ui.DEFAULT_THEME = "forgejo-auto";
        "ui.meta" = {
          AUTHOR = "Git";
          DESCRIPTION = "Developers";
        };
      };
    };

    kanidm.provision.systems.oauth2.forgejo = {
      displayName = "Forgejo";
      originUrl = "https://${endpoint.domains.external}/user/oauth2/kanidm/callback";
      originLanding = "https://${endpoint.domains.external}/user/oauth2/kanidm";
      basicSecretFile = oauthSecretPath;
      preferShortUsername = true;
      scopeMaps."forgejo.access" = [
        "openid"
        "profile"
        "email"
      ];
      claimMaps.groups = {
        joinType = "array";
        valuesByGroup."forgejo.admins" = [ "admin" ];
      };
    };

    nginx.virtualHosts.${endpoint.domains.external} = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "/robots.txt".extraConfig = ''
          return 200 "User-agent: *\nDisallow: /\n";
          add_header Content-Type text/plain;
        '';
        "/".proxyPass = "http://${endpoint.bind}:${toString endpoint.port}";
      };
    };
  };

  systemd.services.forgejo = {
    after = [
      "network-online.target"
      "blocky.service"
      "nginx.service"
      "kanidm.service"
    ];
    wants = [ "network-online.target" ];
    serviceConfig.RestartSec = "10";
    preStart =
      let
        exe = lib.getExe config.services.forgejo.package;
        providerName = "kanidm";
        clientId = "forgejo";
        args = lib.escapeShellArgs [
          "--name" providerName
          "--provider" "openidConnect"
          "--key" clientId
          "--auto-discover-url" "https://${kanidmEndpoint.domains.external}/oauth2/openid/${clientId}/.well-known/openid-configuration"
          "--scopes" "email"
          "--scopes" "profile"
          "--icon-url" "https://kamoshi.org/static/svg/arstotzka.svg"
          "--group-claim-name" "groups"
          "--admin-group" "admin"
          "--skip-local-2fa"
        ];
      in
      lib.mkAfter ''
        provider_id=$(${exe} admin auth list | ${pkgs.gnugrep}/bin/grep -w '${providerName}' | cut -f1)
        SECRET="$(< ${oauthSecretPath})"
        if [[ -z "$provider_id" ]]; then
          ${exe} admin auth add-oauth ${args} --secret "$SECRET"
        else
          ${exe} admin auth update-oauth --id "$provider_id" ${args} --secret "$SECRET"
        fi
      '';
  };

  # Backup
  # ----------
  systemd.tmpfiles.rules = [
    "d /var/backup/forgejo/ 0700 git git -"
  ];

  services.restic.backups.daily.paths = [ "/var/backup/forgejo/" ];

  services.forgejo.dump = {
    enable = true;
    type = "tar";
    file = "dump";
    backupDir = "/var/backup/forgejo/";
  };
}

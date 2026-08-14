{ config, inventory, pkgs, ... }:
let
  endpoint = inventory.endpoints.kanidm;
  certs = config.security.acme.certs.${endpoint.domains.external};
in
{
  services.kanidm = {
    package = pkgs.kanidmWithSecretProvisioning_1_11;

    server = {
      enable = true;
      settings = {
        domain = endpoint.domains.external;
        origin = "https://${endpoint.domains.external}";
        tls_chain = "${certs.directory}/fullchain.pem";
        tls_key = "${certs.directory}/key.pem";
        http_client_address_info = {
          x-forward-for = [ "127.0.0.1" "::1" ];
        };
        bindaddress = "${endpoint.bind}:${toString endpoint.port}";

        online_backup = {
          path = "/var/backup/kanidm/";
          schedule = "0 20 * * *"; # UTC time
          versions = 2;
        };
      };
    };

    client = {
      enable = true;
      settings = {
        uri = "https://${endpoint.domains.external}";
      };
    };

    provision = {
      enable = true;
      autoRemove = true;

      persons = {
        kamov = {
          displayName = "kamov";
          mailAddresses = [ "maciej@kamoshi.org" ];
          groups = [
            "miniflux.access"

            "forgejo.access"
            "forgejo.admins"

          ];
        };
      };

      groups = {
        # Miniflux
        "miniflux.access" = { };
        # Forgejo
        "forgejo.access" = { };
        "forgejo.admins" = { };
      };

      systems.oauth2 = { };
    };
  };

  systemd.services.kanidm = {
    after = [
      "acme-selfsigned-${endpoint.domains.external}.target"
      "acme-finished-${endpoint.domains.external}.target"
    ];
    serviceConfig = {
      SupplementaryGroups = [ certs.group ];
      BindReadOnlyPaths = [ certs.directory ];
      BindPaths = [ "/var/lib/kanidm" ];
    };
  };

  # Backup
  # ----------
  services.restic.backups.daily.paths = [
    "/var/backup/kanidm/"
  ];

  # Network
  # ----------
  services.nginx.virtualHosts.${endpoint.domains.external} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "https://${endpoint.bind}:${toString endpoint.port}";
    };
  };
}

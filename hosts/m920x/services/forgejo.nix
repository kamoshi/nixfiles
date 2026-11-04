{ pkgs, ... }:
{
  users.groups."git" = {};

  users.users."git" = {
    isSystemUser = true;
    group = "git";
    home = "/var/lib/forgejo";
    createHome = false;
    useDefaultShell = true;
  };

  services.forgejo = {
    package = pkgs.forgejo;
    enable = true;
    user = "git";
    group = "git";

    lfs.enable = false;

    settings = {
      server = {
        PROTOCOL = "http+unix";
        HTTP_ADDR = "/run/forgejo/forgejo.sock";
        UNIX_SOCKET_PERMISSION = "0660";

        DOMAIN = "git.kamoshi.org";
        ROOT_URL = "https://git.kamoshi.org/";
        LANDING_PAGE = "explore";
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
    };
  };

  systemd.services = {
    # Allow caddy to communicate with forgejo socket
    caddy.serviceConfig = {
      SupplementaryGroups = [ "git" ];
    };
  };

  services.blocky = {
    settings.customDNS.mapping."git.internal" = "10.1.0.1";
  };

  services.caddy = {
    enable = true;

    virtualHosts."git.internal".extraConfig = ''
      bind 10.1.0.1 10.0.0.5
      tls internal
      reverse_proxy unix//run/forgejo/forgejo.sock
    '';
  };
}

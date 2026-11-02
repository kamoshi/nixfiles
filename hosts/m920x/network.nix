{ config, vpn, ... }:
{
  sops.secrets = {
    wifi = {
      owner = "root";
      group = "wpa_supplicant";
      mode = "0640";
      restartUnits = [ "wpa_supplicant.service" ];
    };
    wg-gensokyo = {
      owner = "root";
      group = "systemd-network";
      mode = "0640";
      restartUnits = [ "systemd-networkd.service" ];
    };
    wg-mesh = {
      owner = "root";
      group = "systemd-network";
      mode = "0640";
      restartUnits = [ "systemd-networkd.service" ];
    };
  };

  services.resolved.enable = true;

  networking = {
    hostName = "m920x";

    useNetworkd = true;
    useDHCP = false;
    dhcpcd.enable = false;

    firewall.allowedUDPPorts = [ 51820 ];

    wireless = {
      enable = true;
      secretsFile = config.sops.secrets."wifi".path;

      networks = {
        "UPC4399823" = {
          pskRaw = "ext:home_psk";
        };
      };
    };
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;

    netdevs = {
      "50-gensokyo" = {
        netdevConfig = {
          Name = "gensokyo";
          Kind = "wireguard";
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets."wg-gensokyo".path;
          ListenPort = vpn.listenPort;
        };
        wireguardPeers = [
          {
            PublicKey = "DML57aZ4EKYT330ncFL5j6aj4wlWyArfKzwjuCF0jAs=";
            AllowedIPs = [ "10.0.0.0/24" ];
            Endpoint = "94.130.182.219:42069";
            PersistentKeepalive = 25;
          }
        ];
      };
      "60-mesh" = {
        netdevConfig = {
          Name = "mesh";
          Kind = "wireguard";
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets."wg-mesh".path;
          ListenPort = 51820;
        };
        wireguardPeers = [
          {
            PublicKey = "n/W27VjB9H9ob7lSDdg4S24FolEO2Z+EHdmcxpIrdS0=";
            AllowedIPs = [ "10.1.0.2/32" ];
          }
        ];
      };
    };

    networks = {
      "20-lan" = {
        matchConfig.Name = "en* wl*";
        networkConfig.DHCP = "yes";
        linkConfig.RequiredForOnline = "routable";
      };
      "50-gensokyo" = {
        matchConfig.Name = "gensokyo";
        address = vpn.ips;
        dns = [ "10.0.0.1" ];
        domains = [ "~." ];
        linkConfig.RequiredForOnline = "no";
      };
      "60-mesh" = {
        matchConfig.Name = "mesh";
        address = [ "10.1.0.1/24" ];
        linkConfig.RequiredForOnline = "no";
      };
    };
  };
}

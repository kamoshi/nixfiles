{ ... }:
{
  networking.firewall.interfaces.mesh = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  services.blocky = {
    enable = true;

    settings = {
      ports.dns = [ "10.1.0.1:53" ];

      upstreams.groups.default = [
        "https://dns.quad9.net/dns-query"
      ];

      bootstrapDns = {
        upstream = "https://dns.quad9.net/dns-query";
        ips = [ "9.9.9.9" "149.112.112.112" ];
      };

      customDNS = {
        customTTL = "1h";
        mapping = {
          "ca.internal" = "10.1.0.1";
          "music.internal" = "10.1.0.1";
        };
      };
    };
  };
}

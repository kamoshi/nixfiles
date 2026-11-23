{ config, ... }:

{
  networking.firewall.interfaces.mesh = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  services.unbound = {
    enable = true;

    settings = {
      server = {
        # Listen on the mesh IP
        interface = [ "10.1.0.1" ];
        port = 53;

        # "respip" is required for RPZ to function
        module-config = ''"respip validator iterator"'';

        # Allow DNS requests from the mesh network
        access-control = [
          "10.1.0.0/24 allow"
          "127.0.0.0/8 allow"
        ];

        # Local DNS record
        local-zone = [
          "internal. static"
        ];

        local-data = [
          ''"m920x.internal. 3600 IN A 10.1.0.1"''
          ''"ca.internal. 3600 IN CNAME m920x.internal."''
        ];

        # DNSSEC validation
        qname-minimisation = true;
      };

      rpz = [
        {
          name = "tif.medium";
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/rpz/tif.medium.txt";
          zonefile = "${config.services.unbound.stateDir}/tif.medium.rpz";
          rpz-log = true;
          rpz-log-name = "tif.medium";
        }
        {
          name = "nsfw";
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/rpz/nsfw.txt";
          zonefile = "${config.services.unbound.stateDir}/nsfw.rpz";
          rpz-log = true;
          rpz-log-name = "nsfw";
        }
      ];

      # Quad9 DNS-over-TLS
      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = true;

          forward-addr = [
            "9.9.9.9@853#dns.quad9.net"
            "149.112.112.112@853#dns.quad9.net"
          ];

          # Fallback to recursive resolution on SERVFAIL
          forward-first = true;
        }
      ];
    };
  };
}

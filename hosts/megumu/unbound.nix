{ ... }:
{
  networking.nameservers = [
    "127.0.0.1"
    "::1"
  ];

  services.blocky = {
    enable = true;

    settings = {
      ports.dns = 53; # Port for incoming DNS Queries.
      upstreams.groups.default = [
        "127.0.0.1:5353"
        "[::1]:5353"
      ];

      # For initially solving DoH/DoT Requests when no system resolver is available.
      bootstrapDns = {
        upstream = "https://dns.quad9.net/dns-query";
        ips = [
          "9.9.9.9"
          "149.112.112.112"
        ];
      };

      blocking = {
        blockType = "zeroIP";

        blackLists = {
          crap = [
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/pro.txt"
            "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/tif.txt"
            "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/nsfw.txt"
          ];
          social = [
            # "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/social.txt"
            # ./filters/hackernews.txt
            # ./filters/wykop.txt
            # ./filters/reddit.txt
          ];
        };

        allowlists = {
          social = [
            ./filters/discord.txt
          ];
        };

        clientGroupsBlock = {
          default = [
            "crap"
            "social"
          ];
        };
      };

      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };
    };
  };

  # Blocky serves internal DNS to WireGuard peers only.
  networking.firewall.interfaces.gensokyo = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  services.unbound = {
    enable = true;

    enableRootTrustAnchor = true;

    settings = {
      server = {
        port = 5353;

        interface = [
          "127.0.0.1"
          "::1"
        ];

        access-control = [
          "127.0.0.1/32 allow"
          "::1/128 allow"
        ];

        # Hide identity and version for security
        hide-identity = true;
        hide-version = true;

        # Hardening options
        harden-glue = true;
        harden-dnssec-stripped = true;
        harden-below-nxdomain = true;
        qname-minimisation = true;

        # Performance and cache options
        prefetch = true;
        prefetch-key = true;
        serve-expired = true;
      };
    };
  };
}

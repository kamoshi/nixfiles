{ ... }:
{
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53;
      upstreams.groups.default = [
        "127.0.0.1:5353"
        "[::1]:5353"
      ];
      blocking = {
        denylists = {
          #Adblocking
          ads = ["https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"];
          #Another filter for blocking adult sites
          adult = ["https://blocklistproject.github.io/Lists/porn.txt"];
          #You can add additional categories
        };
        clientGroupsBlock = {
          default = [ "ads" "adult" ];
        };
      };
      # caching = {
      #   minTime = "5m";
      #   maxTime = "30m";
      #   prefetching = true;
      # };
    };
  };

  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [
          "127.0.0.1"
          "::1"
        ];
        port = 5353;
        access-control = [
          "127.0.0.1/32 allow"
          "::1/128 allow"
        ];
        # Based on recommended settings in https://docs.pi-hole.net/guides/dns/unbound/#configure-unbound
        harden-glue = true;
        harden-dnssec-stripped = true;
        use-caps-for-id = false;
        prefetch = true;
        edns-buffer-size = 1232;

        # Custom settings
        hide-identity = true;
        hide-version = true;
      };
      forward-zone = [
        # Example config with quad9
        {
          name = ".";
          forward-addr = [
            "9.9.9.9#dns.quad9.net"
            "149.112.112.112#dns.quad9.net"
            "2620:fe::fe#dns.quad9.net"
            "2620:fe::9#dns.quad9.net"
          ];
          forward-tls-upstream = true;  # Protected DNS
        }
      ];
    };
  };
}

{ ... }:
let
  domain = "jellyfin.internal";
  port = 8096;
in {
  services.jellyfin = {
    enable = true;
    user = "jellyfin";

    # We don't want the whole world to see it.
    openFirewall = false;
  };

  networking.firewall = {
    # Open ONLY for WireGuard
    interfaces."wg0" = {
      allowedTCPPorts = [ port ];
    };
  };

  # Ensure Jellyfin can see the SSHFS mount
  systemd.services.jellyfin = {
    # Force Jellyfin to wait until /data is actually mounted
    requires = [ "data.mount" ];
    after = [ "data.mount" "network-online.target" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts.${domain}.extraConfig = ''
      bind 10.0.0.1
      tls internal
      reverse_proxy 127.0.0.1:${toString port}
    '';
  };

  services.blocky = {
    settings.customDNS.mapping.${domain} = "10.0.0.1";
  };
}

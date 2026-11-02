{ ... }:
{
  security.pki.certificateFiles = [ ../../ca-root.crt ];

  networking.firewall.interfaces."gensokyo" = {
    allowedTCPPorts = [ 80 443 ];
  };

  services.caddy = {
    enable = true;

    globalConfig = ''
      acme_ca https://ca.internal/acme/local/directory
      acme_ca_root /etc/caddy/ca-root.crt
    '';
  };

  services.blocky.settings.customDNS.mapping = {
    "ca.internal" = "10.0.0.5";
  };
}

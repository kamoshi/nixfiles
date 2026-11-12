{ ... }:
let
  ip = "10.0.0.5";
  domain = "media.internal";
in
{
  networking.hosts.${ip} = [ domain ];

  services.blocky = {
    settings.customDNS.mapping.${domain} = ip;
  };
}

{ ... }:
{
  networking.hosts."10.0.0.5" = [ "rss.internal" ];

  services.blocky = {
    settings.customDNS.mapping."rss.internal" = "10.0.0.5";
  };
}

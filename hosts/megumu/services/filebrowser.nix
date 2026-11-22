{ ... }:
{
  networking.hosts."10.0.0.5" = [ "files.internal" ];

  services.blocky = {
    settings.customDNS.mapping."files.internal" = "10.0.0.5";
  };
}

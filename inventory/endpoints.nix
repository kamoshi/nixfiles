{
  calibre = {
    host = "megumu";
    bind = "vpn";
    port = 9998;
    domains.internal = "calibre.internal";
  };

  forgejo = {
    host = "megumu";
    bind = "loopback";
    port = 3200;
    domains.external = "git.kamoshi.org";
  };

  fukurou = {
    host = "m920x";
    bind = "vpn";
    port = 4321;
    internalPort = 4322;
    domains = {
      internal = "fukurou.internal";
      external = "api.kamoshi.org";
    };
  };

  glance = {
    host = "megumu";
    bind = "loopback";
    port = 9292;
    domains.external = "glance.kamoshi.org";
  };

  immich = {
    host = "m920x";
    bind = "vpn";
    port = 2283;
    proxyPort = 2285;
    domains = {
      internal = "photos.internal";
      external = "photos.kamoshi.org";
    };
  };

  karasu = {
    host = "megumu";
    bind = "loopback";
    port = 4323;
    domains.external = "karasu.kamoshi.org";
  };

  jellyfin = {
    host = "megumu";
    bind = "loopback";
    port = 8096;
    domains.internal = "jellyfin.internal";
  };

  kanidm = {
    host = "megumu";
    bind = "loopback";
    port = 8443;
    domains.external = "auth.kamoshi.org";
  };

  miniflux = {
    host = "megumu";
    bind = "loopback";
    port = 2137;
    domains.external = "rss.kamoshi.org";
  };

  navidrome = {
    host = "m920x";
    bind = "vpn";
    port = 4533;
    domains = {
      internal = "music.internal";
      external = "music.kamoshi.org";
    };
  };

  syncthing = {
    host = "megumu";
    bind = "vpn";
    port = 8384;
    domains.internal = "syncthing.megumu.internal";
  };

  woodpecker = {
    host = "megumu";
    bind = "loopback";
    port = 8000;
    domains.external = "ci.kamoshi.org";
  };
}

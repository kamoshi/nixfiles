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
    host = "megumu";
    bind = "loopback";
    port = 4321;
    internalPort = 4322;
    domains = {
      internal = "fukurou.internal";
      external = "api.kamoshi.org";
    };
  };

  gatus = {
    host = "megumu";
    bind = "loopback";
    port = 2138;
    domains.external = "status.kamoshi.org";
  };

  glance = {
    host = "megumu";
    bind = "loopback";
    port = 9292;
    domains.external = "glance.kamoshi.org";
  };

  grafana = {
    host = "megumu";
    bind = "loopback";
    port = 2139;
    domains.external = "data.kamoshi.org";
  };

  immich = {
    host = "megumu";
    bind = "loopback";
    port = 2283;
    proxyPort = 2285;
    domains = {
      internal = "photos.internal";
      external = "photos.kamoshi.org";
    };
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
    host = "megumu";
    bind = "loopback";
    port = 4533;
    domains = {
      internal = "music.internal";
      external = "music.kamoshi.org";
    };
  };

  syncthing = {
    host = "megumu";
    bind = "loopback";
    port = 8384;
    domains.internal = "syncthing.internal";
  };

  vikunja = {
    host = "megumu";
    bind = "loopback";
    port = 6969;
    domains.external = "kanban.kamoshi.org";
  };

  woodpecker = {
    host = "megumu";
    bind = "loopback";
    port = 8000;
    domains.external = "ci.kamoshi.org";
  };
}

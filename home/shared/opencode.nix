{ config, nightly, utils, ... }:
{
  home.packages = [
    nightly.opencode
  ];

  xdg.configFile = utils.home.xdgSymlink config [
    "opencode"
  ];
}

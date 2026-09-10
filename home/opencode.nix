{ config, rolling, utils, ... }:
{
  home.packages = [
    rolling.opencode
  ];

  xdg.configFile = utils.home.xdgSymlink config [
    "opencode"
  ];
}

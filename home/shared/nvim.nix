{ config, utils, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
    sideloadInitLua = true;
  };

  xdg.configFile = utils.home.xdgSymlink config [
    "nvim"
  ];

  home.sessionVariables.EDITOR = "nvim";
}

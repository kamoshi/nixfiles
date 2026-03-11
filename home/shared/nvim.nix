{ config, utils, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  xdg.configFile = utils.home.symlink config [
    "nvim"
  ];

  home.sessionVariables.EDITOR = "nvim";
}

{ config, rolling, utils, ... }:
{
  home.file = utils.home.symlink config [
    ".claude/skills"
  ];

  home.packages = [
    rolling.claude-code
  ];
}

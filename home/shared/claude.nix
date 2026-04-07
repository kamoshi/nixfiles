{ config, nightly, utils, ... }:
{
  home.file = utils.home.symlink config [
    ".claude/skills"
  ];

  home.packages = [
    nightly.claude-code
  ];
}

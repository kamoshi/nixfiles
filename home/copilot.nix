{ rolling, ... }:
{
  home.packages = with rolling; [
    github-copilot-cli
  ];
}

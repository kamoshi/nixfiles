{ nightly, ... }:
{
  home.packages = with nightly; [
    github-copilot-cli
  ];
}

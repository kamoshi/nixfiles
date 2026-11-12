{ rolling, ... }:
{
  home.packages = [
    (rolling.codex.overrideAttrs (old: {
      AWS_LC_SYS_USE_SYSTEM = "0";
    }))
  ];
}

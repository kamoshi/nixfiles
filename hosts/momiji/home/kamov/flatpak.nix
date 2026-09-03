{ pkgs, ... }:
let
  meikipop =
    let
      appId = "com.github.rtr46.meikipop";
    in
    rec {
      inherit appId;
      sha256 = "96bcafe386a754a6f835a3375bbff9cf13f5e64d44579663b38c4d07c9c3c25b";
      bundle = "${pkgs.fetchurl {
        url = "https://github.com/rtr46/meikipop/releases/download/v2.0.4/meikipop.linux.x64.flatpak";
        inherit sha256;
      }}";
    };
in
{
  services.flatpak = {
    enable = true;

    packages = [
      meikipop
    ];
  };
}

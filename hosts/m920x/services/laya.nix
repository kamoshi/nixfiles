{ laya, pkgs, ... }:

let
  cpuPythonPackages = pkgs.python3Packages // {
    # Reuse upstream's package definition, but replace CUDA torch-bin.
    torch-bin = pkgs.python3Packages.torch;
  };

  layaPackage =
    (pkgs.callPackage "${laya}/nix/package.nix" {
      python3Packages = cpuPythonPackages;
    }).laya-serve;
in

{
  services.laya-serve = {
    enable = true;
    package = layaPackage;

    host = "127.0.0.1";
    port = 8000;
    device = "cpu";

    models = [
      "english"
      "multilingual"
    ];

    preload = true;
    threads = 4;
    maxConcurrent = 2;
    openFirewall = false;
  };

  services.caddy.virtualHosts."laya.internal".extraConfig = ''
    bind 10.1.0.1 [fd00::1] 10.0.0.5
    tls internal
    reverse_proxy 127.0.0.1:8000
  '';
}

{
  inputs,
  Type,
}:
let
  inherit (inputs) fukurou karasu sops-nix;
in
{
  # aya
  aya = {
    id = "K53ML2R-XXPRH3Z-SB7RKVP-UZCWTDA-636J5O4-442XL3U-O7ZA7Y4-K4THEQY";
    name = "Aya";
    type = Type.Darwin;
    arch = "aarch64-darwin";
    modules = [
      # Let Determinate Nix handle Nix configuration
      (
        { ... }:
        {
          nix.enable = false;
        }
      )
      sops-nix.darwinModules.sops
      ../hosts/aya
    ];
    home = {
      kamov = ../home/roles/daily.nix;
    };
    vpn = {
      ip = "10.0.0.4";
      pubkey = "sJ5ri5XPMgsMsHTZVR9mzo02JRubA13Zoh6lKNMTqEE=";
    };
  };

  # momiji
  momiji = {
    id = "24FX4TW-B2RVLIO-DXXDZWP-4XQAE4H-NHKLMLK-5SJZCIV-45OBS2N-MJEYNQ2";
    name = "Momiji";
    type = Type.Home;
    arch = "x86_64-linux";
    modules = [
      inputs.sops-nix.homeManagerModules.sops
      ../home/roles/daily.nix
    ];
    vpn = {
      ip = "10.0.0.2";
      pubkey = "9UISV736vJr39rHCvTuJeF72vjSxnD8DJgF0NZYzLTU=";
    };
  };

  # hatate
  hatate = {
    id = "C7YIZDV-2PYEKKM-T2ZOOKR-FCJUXU3-I4AOAWP-Y7HT663-JQNICD5-56BTCAC";
    name = "Hatate";
    vpn = {
      ip = "10.0.0.3";
      pubkey = "32PZKaWNzCwpCZVhLOGal/Pupe/gDVLDeEfdjlsM7y0=";
    };
  };

  # megumu
  megumu = {
    id = "3R3IGHH-6Y2WZHC-R6EYP3U-55TP653-I4UMF3V-KIY3DUA-GCEQRYS-3BXBBQD";
    name = "Megumu";
    type = Type.NixOS;
    arch = "x86_64-linux";
    modules = [
      sops-nix.nixosModules.sops
      fukurou.nixosModules.default
      karasu.nixosModules.default
      ../hosts/megumu
    ];
    home = {
      kamov = ../home/roles/server.nix;
    };
    vpn = {
      ip = "10.0.0.1";
      pubkey = "DML57aZ4EKYT330ncFL5j6aj4wlWyArfKzwjuCF0jAs=";
      server = true;
      endpoint = "94.130.182.219";
    };
  };
}

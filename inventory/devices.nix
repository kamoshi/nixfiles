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
      kamov = ../hosts/aya/home/kamov.nix;
    };
    vpn = {
      ip = "10.0.0.4";
      pubkey = "sJ5ri5XPMgsMsHTZVR9mzo02JRubA13Zoh6lKNMTqEE=";
    };
  };

  # momiji
  momiji = {
    id = "V5CJGN4-TTH7STB-XZA7PGZ-SRBVVM7-GDGS5VX-YMRNXVZ-55MFIMO-QTOYDAW";
    name = "Momiji";
    type = Type.NixOS;
    arch = "x86_64-linux";
    modules = [
      sops-nix.nixosModules.sops
      ../hosts/momiji
    ];
    home = {
      kamov = ../hosts/momiji/home/kamov.nix;
    };
    vpn = {
      ip = "10.0.0.2";
      pubkey = "bJx1OJDnDCC7kEhiLtBUbrz11ZXMfpn/7mE+JFAL2WY=";
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
      kamov = ../hosts/megumu/home/kamov.nix;
    };
    vpn = {
      ip = "10.0.0.1";
      pubkey = "DML57aZ4EKYT330ncFL5j6aj4wlWyArfKzwjuCF0jAs=";
      server = true;
      endpoint = "94.130.182.219";
    };
  };
}

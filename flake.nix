{
  description = "System configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nightly.url = "github:nixos/nixpkgs/nixos-unstable";

    # aarch64-darwin
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # dotfiles
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # secrets
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fukurou = {
      url = "github:/kamoshi/fukurou";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    karasu = {
      url = "git+https://git.kamoshi.org/kamov/karasu";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      util = import ./util inputs;
      lib = nixpkgs.lib;

      Type = {
        NixOS = 0;
        Darwin = 1;
        Home = 2;
      };

      matches =
        type: _: system:
        system ? "type" && system.type == type;

      devices = import ./inventory/devices.nix { inherit inputs Type; };
      endpoints = import ./inventory/endpoints.nix;
      syncFolders = import ./inventory/sync.nix;

      resolveBind =
        device: bind:
        if bind == "vpn" then
          device.vpn.ip
        else if bind == "loopback" then
          "127.0.0.1"
        else
          bind;

      resolveEndpoint = device: endpoint: endpoint // { bind = resolveBind device endpoint.bind; };

      endpointsFor =
        key:
        lib.pipe endpoints [
          (lib.filterAttrs (_: endpoint: endpoint.host == key))
          (lib.mapAttrs (_: endpoint: resolveEndpoint devices.${key} endpoint))
        ];

      syncPath = entry: if lib.isAttrs entry then entry.path else entry;
      syncFor =
        key:
        lib.pipe syncFolders [
          (lib.filterAttrs (_: folder: lib.hasAttr key folder.path))
          (lib.mapAttrs (_: folder: syncPath folder.path.${key}))
        ];

      meshFor =
        key: config:
        util.meshFor {
          inherit devices key config;
          folders = syncFolders;
        };
      vpnFor =
        key:
        util.vpnFor {
          inherit devices key;
        };

      mkConfig =
        builder: key: device:
        builder {
          inherit
            meshFor
            vpnFor
            key
            device
            ;
          inventory = {
            endpoints = endpointsFor key;
            sync = syncFor key;
          };
        };
    in
    {
      nixosConfigurations = lib.pipe devices [
        (lib.filterAttrs (matches Type.NixOS))
        (lib.mapAttrs (mkConfig util.mkNixOS))
      ];

      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#aya
      darwinConfigurations = lib.pipe devices [
        (lib.filterAttrs (matches Type.Darwin))
        (lib.mapAttrs (mkConfig util.mkDarwin))
      ];

      homeConfigurations = lib.pipe devices [
        (lib.filterAttrs (matches Type.Home))
        (lib.mapAttrs (mkConfig util.mkHome))
      ];
    };
}

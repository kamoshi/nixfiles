inputs@{
  self,
  nixpkgs,
  nightly,
  nix-darwin,
  home-manager,
  ...
}:
let
  lib = nixpkgs.lib;
  homeUtils = import ./home.nix inputs;

  pkgsFor =
    system:
    import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

  nightlyFor =
    system:
    import nightly {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          # Use headless ghostscript (no CUPS, no X11) inside imagemagickBig
          # to avoid pulling cups-2.4 into the closure via calibre-web → wand
          imagemagickBig = prev.imagemagick.override {
            ghostscriptSupport = true;
            ghostscript = final.ghostscript_headless;
          };
        })
      ];
    };

  mkExtraSpecialArgs =
    {
      device,
      mesh,
      vpn,
    }:
    {
      nightly = nightlyFor device.arch;

      inherit
        device
        mesh
        vpn
        ;
    };

  mkHomeUtils =
    {
      vpnFor ? null,
    }:
    {
      home = homeUtils;
    }
    // lib.optionalAttrs (vpnFor != null) {
      inherit vpnFor;
    };

  mkHomeExtraSpecialArgs =
    {
      device,
      mesh,
      vpn,
      vpnFor ? null,
    }:
    mkExtraSpecialArgs { inherit device mesh vpn; }
    // {
      utils = mkHomeUtils { inherit vpnFor; };
    };

  homeManagerModules =
    {
      type,
      device,
      mesh,
      vpn,
    }:
    lib.optionals (device ? home) [
      home-manager."${type}Modules".home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users = device.home;
          sharedModules = [
            inputs.sops-nix.homeManagerModules.sops
          ];
          extraSpecialArgs = mkHomeExtraSpecialArgs { inherit device mesh vpn; };
        };
      }
    ];

  mkDeviceContext =
    {
      meshFor,
      vpnFor,
      key,
      device,
    }:
    let
      deviceWithKey = device // {
        inherit key;
      };
    in
    {
      device = deviceWithKey;
      mesh = meshFor key;
      vpn = vpnFor key;
    };

  isVpnServer = device: device.vpn.server or false;

  vpnDevices = devices: lib.filterAttrs (_: device: device ? vpn) devices;

  vpnPeersFor =
    {
      devices,
      key,
    }:
    let
      local = devices.${key};
      candidates = vpnDevices devices;
    in
    lib.mapAttrsToList (_: device: device) (
      if isVpnServer local then
        lib.filterAttrs (name: _: name != key) candidates
      else
        lib.filterAttrs (_: isVpnServer) candidates
    );

  mkWireGuardPeer = device: {
    publicKey = device.vpn.pubkey;
    allowedIPs = [ "${device.vpn.ip}/32" ];
  };

  mkWireGuardPeerText = listenPort: device: ''
    [Peer]
    PublicKey = ${device.vpn.pubkey}
    AllowedIPs = ${device.vpn.ip}/32
    ${lib.optionalString (isVpnServer device) ''
      Endpoint = ${device.vpn.endpoint}:${toString listenPort}
      PersistentKeepalive = 25
    ''}
  '';

  folderPeerNames =
    {
      folderDevices,
      key,
    }:
    lib.filter (name: name != key) (lib.attrNames folderDevices);

  encryptedFolderDeviceNames =
    folderDevices:
    lib.filter (
      name:
      let
        entry = folderDevices.${name};
      in
      lib.isAttrs entry && entry ? encrypted
    ) (lib.attrNames folderDevices);

  folderPath = entry: if lib.isAttrs entry then entry.path else entry;

  mkSyncthingFolder =
    {
      config,
      key,
      folder,
    }:
    let
      folderDevices = folder.path;
      localEntry = folderDevices.${key};
      encryptedDevices = encryptedFolderDeviceNames folderDevices;
      localReceivesEncrypted = lib.elem key encryptedDevices;

      mkPeer =
        peerName:
        if !localReceivesEncrypted && lib.elem peerName encryptedDevices then
          {
            name = peerName;
            encryptionPasswordFile = config.sops.secrets.${folderDevices.${peerName}.encrypted}.path;
          }
        else
          peerName;
    in
    folder
    // {
      path = folderPath localEntry;
      devices = map mkPeer (folderPeerNames {
        inherit folderDevices key;
      });
    }
    // lib.optionalAttrs localReceivesEncrypted {
      type = "receiveencrypted";
    };

  mkSyncthingDevice = _: device: {
    inherit (device) id name;
  };
in
{
  mkNixOS =
    args:
    let
      ctx = mkDeviceContext args;
    in
    lib.nixosSystem {
      system = ctx.device.arch;
      modules =
        ctx.device.modules
        ++ homeManagerModules {
          type = "nixos";
          inherit (ctx) device mesh vpn;
        };
      specialArgs = mkExtraSpecialArgs ctx // {
        inherit self;
      };
    };

  mkDarwin =
    args:
    let
      ctx = mkDeviceContext args;
    in
    nix-darwin.lib.darwinSystem {
      system = ctx.device.arch;
      modules =
        ctx.device.modules
        ++ homeManagerModules {
          type = "darwin";
          inherit (ctx) device mesh vpn;
        };
      specialArgs = mkExtraSpecialArgs ctx // {
        inherit self;
      };
    };

  mkHome =
    args:
    let
      ctx = mkDeviceContext args;
    in
    home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor ctx.device.arch;
      modules = ctx.device.modules;
      extraSpecialArgs = mkHomeExtraSpecialArgs (
        {
          inherit (ctx) device mesh vpn;
        }
        // {
          inherit (args) vpnFor;
        }
      );
    };

  meshFor =
    {
      devices,
      folders,
      key,
      config,
    }:
    {
      devices = lib.pipe devices [
        (lib.filterAttrs (name: _: name != key))
        (lib.mapAttrs mkSyncthingDevice)
      ];
      folders = lib.pipe folders [
        (lib.filterAttrs (_: folder: lib.hasAttr key folder.path))
        (lib.mapAttrs (folderName: folder:
          let
            invalidPeers = lib.filter (name: !lib.hasAttr name devices) (lib.attrNames folder.path);
          in
          if invalidPeers != [] then
            throw "Folder '${folderName}' references undefined device(s) in inventory/folders.nix: ${lib.concatStringsSep ", " invalidPeers}"
          else
            mkSyncthingFolder { inherit config key folder; }
        ))
      ];
    };

  vpnFor =
    {
      devices,
      key,
    }:
    let
      local = devices.${key};
      listenPort = 42069;
      peers = vpnPeersFor { inherit devices key; };
    in
    {
      ips = [ "${local.vpn.ip}/24" ];
      inherit listenPort;

      peers = map mkWireGuardPeer peers;

      text = ''
        [Interface]
        Address = ${local.vpn.ip}/24
        ListenPort = ${toString listenPort}
        PrivateKey = <private_key>

        ${lib.concatMapStringsSep "\n" (mkWireGuardPeerText listenPort) peers}
      '';
    };
}

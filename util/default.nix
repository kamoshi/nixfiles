inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
# Functions that takes a system's name and its configuration,
# and return the appropriate flake output.
let
  utilsHome = import ./home.nix inputs;
  lib       = nixpkgs.lib;

  maybeAttachHome = type: device: mesh: vpn:
    if device ? "home"
      then [
        home-manager."${type}Modules".home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users = device.home;
            sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
            ];
            extraSpecialArgs = {
              inherit device mesh vpn;
              utils = { home = utilsHome; };
            };
          };
        }
      ]
      else [];

  mkNixOS = meshFor: vpnFor: key: device:
    let
      mesh = meshFor key;
      vpn  = vpnFor key;
    in
      lib.nixosSystem {
        system = device.arch; # "x86_64-linux"
        modules = device.modules ++ maybeAttachHome "nixos" device mesh vpn;
        specialArgs = {
          inherit self device mesh vpn;
        };
      };

  mkDarwin = meshFor: vpnFor: key: device:
    let
      mesh = meshFor key;
      vpn  = vpnFor key;
    in
      nix-darwin.lib.darwinSystem {
        system = device.arch;
        modules = device.modules ++ maybeAttachHome "darwin" device mesh vpn;
        specialArgs = {
          inherit self device mesh vpn;
        };
      };

  mkHome = meshFor: vpnFor: key: device:
    let
      mesh = meshFor key;
      vpn  = vpnFor key;
    in
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${device.arch};

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = device.modules;

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {
          inherit device mesh vpn;
          utils = {
            inherit vpnFor;
            home = utilsHome;
          };
        };
      };

  meshFor = devices: folders: key: config: {
    devices =
      lib.pipe devices [
        (lib.filterAttrs (other: _: other != key))
        (lib.mapAttrs (_: device: { inherit (device) id name; }))
      ];
    folders =
      lib.pipe folders [
        (lib.filterAttrs (_: folder: lib.hasAttr key folder.path))
        (lib.mapAttrs (_: folder:
          let
            devices = folder.path;
            myConfig = devices.${key};
            peerNames = lib.filter (d: d != key) (lib.attrNames devices);

            # list of names for all devices that require encryption
            untrustedTargetNames = lib.filter
              (name: devices.${name} ? "encrypted")
              (lib.attrNames devices);

            # am I one of the untrusted ones?
            iAmUntrusted = lib.elem key untrustedTargetNames;

            mkDeviceEntry = peerName:
              # if I am trusted (host) AND the peer is untrusted...
              if !iAmUntrusted && (lib.elem peerName untrustedTargetNames) then {
                name = peerName;
                # we grab the password file specifically for *this* peer
                encryptionPasswordFile = config.sops.secrets.${devices.${peerName}.encrypted}.path;
              } else
                peerName;
          in
            folder
              // {
                path = if lib.isAttrs myConfig then myConfig.path else myConfig;
                devices = map mkDeviceEntry peerNames;
              }
              // lib.optionalAttrs iAmUntrusted { type = "receiveencrypted"; }
        ))
      ];
  };

  vpnFor = devices: key:
    let
      device = devices.${key};
      host = device.vpn;
      listenPort = 42069;

      other =
        lib.mapAttrsToList (_: v: v) (
          if host ? "server" && host.server
            then # get all other devices
              lib.filterAttrs (k: v: k != key && v ? "vpn") devices
            else # find server
              lib.filterAttrs (_: v: v ? "vpn" && v.vpn ? "server" && v.vpn.server) devices
        );
    in {
      ips = [ "${host.ip}/24" ];
      inherit listenPort;

      peers =
        map (v: {
          publicKey = v.vpn.pubkey;
          allowedIPs = [ "${v.vpn.ip}/32" ];
        }) other;

      text = ''
        [Interface]
        Address = ${host.ip}/24
        ListenPort = ${toString listenPort}
        PrivateKey = <private_key>

        ${lib.concatMapStringsSep "\n" (peer: ''
          [Peer]
          PublicKey = ${peer.vpn.pubkey}
          AllowedIPs = ${peer.vpn.ip}/32
          ${if peer.vpn ? "server" && peer.vpn.server
            then ''
              Endpoint = ${peer.vpn.endpoint}:${toString listenPort}
              PersistentKeepalive = 25
            ''
            else ""
          }
        '') other}
      '';
    };
in {
  inherit mkNixOS mkDarwin mkHome meshFor vpnFor;
}

{
  config,
  pkgs,
  vpn,
  ...
}:
{
  sops = {
    defaultSopsFile = ./sops.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets.wireguard = {
      mode = "0400";
    };
  };

  # NetworkManager manages the physical links; NixOS manages this interface.
  networking.networkmanager = {
    dns = "systemd-resolved";
    unmanaged = [
      "interface-name:gensokyo"
      "interface-name:mesh"
    ];
  };

  services.resolved.enable = true;

  networking.wireguard = {
    enable = true;

    interfaces.gensokyo = {
      privateKeyFile = config.sops.secrets.wireguard.path;
      inherit (vpn) ips peers listenPort;

      postSetup = ''
        ${pkgs.systemd}/bin/resolvectl dns gensokyo 10.0.0.1
        ${pkgs.systemd}/bin/resolvectl domain gensokyo '~.'
      '';

      postShutdown = ''
        ${pkgs.systemd}/bin/resolvectl revert gensokyo
      '';
    };

    interfaces.mesh = {
      ips = [ "10.1.0.4/32" ];

      listenPort = 51820;

      privateKeyFile = config.sops.secrets.wireguard.path;

      postSetup = ''
        ${pkgs.systemd}/bin/resolvectl dns mesh 10.1.0.1
        ${pkgs.systemd}/bin/resolvectl domain mesh '~photos.internal' '~music.internal'
      '';

      postShutdown = ''
        ${pkgs.systemd}/bin/resolvectl revert mesh
      '';

      peers = [
        {
          publicKey = "y3aDNpKwVEq6+nXd7mmybZjuPIsOhhAMXxwb91w6mx0=";
          allowedIPs = [
            "10.1.0.1/32"
          ];
          endpoint = "192.168.0.100:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}

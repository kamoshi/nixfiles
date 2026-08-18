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
    unmanaged = [ "interface-name:gensokyo" ];
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
  };
}

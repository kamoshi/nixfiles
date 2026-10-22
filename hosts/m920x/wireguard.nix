{ config, pkgs, vpn, ... }:
{
  # NetworkManager manages physical links; NixOS owns this interface.
  networking.networkmanager = {
    dns = "systemd-resolved";
    unmanaged = [ "interface-name:gensokyo" ];
  };

  services.resolved.enable = true;

  networking.wireguard = {
    enable = true;

    interfaces.gensokyo = {
      privateKeyFile = "/etc/wireguard/gensokyo.key";
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

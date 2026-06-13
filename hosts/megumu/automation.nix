{ ... }:
{
  # system.autoUpgrade = {
  #   enable = true;
  #   dates = "04:00";
  #   flake = "git+https://git.kamoshi.org/kamov/nixfiles.git#megumu";
  #   allowReboot = true;
  # };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings.auto-optimise-store = true;
    optimise.automatic = true;
  };

  services.fstrim.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };
}

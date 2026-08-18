{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.espflash
    pkgs.rustup
  ];

  home.sessionVariables = {
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
  };

  home.sessionPath = [
    "${config.xdg.dataHome}/cargo/bin"
  ];
}

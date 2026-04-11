{ nixpkgs, ... }:
let
  symlink = config: dirs: nixpkgs.lib.genAttrs dirs (path: {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/${path}";
  });
  xdgSymlink = config: dirs: nixpkgs.lib.genAttrs dirs (path: {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/.config/${path}";
  });
in {
  inherit symlink xdgSymlink;
}

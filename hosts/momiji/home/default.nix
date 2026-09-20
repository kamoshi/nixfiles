{ inputs }:
{
  kamov.imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    ./kamov
  ];
}

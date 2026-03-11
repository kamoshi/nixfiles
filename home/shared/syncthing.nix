{ config, mesh, ... }:
{
  services.syncthing = {
    enable = true;

    settings = {
      gui = {
        user = "kamov";
        password = "kamov";
      };

      inherit (mesh config) devices folders;
    };
  };
}

{
  nix = {
    id = "nix";
    label = "Nix";
    path = {
      aya = "~/nix";
      momiji = "~/nix";
      megumu = "~/nix";
      nitori = "~/nix";
    };
  };
  calibre = {
    id = "calibre";
    label = "Calibre";
    path = {
      aya = "~/calibre";
      momiji = "~/calibre";
      megumu = "/data/sync/calibre";
    };
  };
  obsidian = {
    id = "obsidian";
    label = "Obsidian";
    path = {
      aya = "~/Desktop/Obsidian";
      momiji = "~/Desktop/Obsidian";
      megumu = {
        path = "/data/sync/obsidian";
        encrypted = "syncthing/obsidian";
      };
    };
  };
  workspace = {
    id = "workspace";
    label = "Workspace";
    path = {
      aya = "~/Desktop/Workspace";
      momiji = "~/Desktop/Workspace";
      megumu = {
        path = "/data/sync/workspace";
        encrypted = "syncthing/workspace";
      };
    };
  };
  photos = {
    id = "photos";
    label = "Photos";
    path = {
      aya = "~/Desktop/Photos";
      hatate = "~/DCIM";
      momiji = "~/Desktop/Photos";
      megumu = {
        path = "/data/sync/photos";
        encrypted = "syncthing/photos";
      };
    };
  };
}

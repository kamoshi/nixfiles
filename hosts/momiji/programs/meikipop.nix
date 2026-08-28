{ pkgs, ... }:
let
  appId = "com.github.rtr46.meikipop";

  meikipop = pkgs.writeShellApplication {
    name = "meikipop";
    runtimeInputs = with pkgs; [
      coreutils
      flatpak
      gnugrep
      gnused
    ];
    text = ''
      app_id="${appId}"
      config_dir="$HOME/.var/app/$app_id/config/meikipop"
      config_file="$config_dir/config.ini"

      mkdir -p "$config_dir"

      if [[ -f "$config_file" ]]; then
        if grep -qE '^[[:space:]]*scan_region[[:space:]]*=' "$config_file"; then
          sed -i -E 's/^[[:space:]]*scan_region[[:space:]]*=.*/scan_region = 0/' "$config_file"
        elif grep -Fxq '[Settings]' "$config_file"; then
          sed -i '/^\[Settings\]$/a scan_region = 0' "$config_file"
        else
          printf '\n[Settings]\nscan_region = 0\n' >> "$config_file"
        fi
      else
        printf '[Settings]\nscan_region = 0\n' > "$config_file"
      fi

      if flatpak ps --columns=application | grep -Fxq "$app_id"; then
        flatpak kill "$app_id"
      fi

      exec flatpak run "$app_id" "$@"
    '';
  };
in
{
  services.flatpak = {
    enable = true;

    packages = [
      rec {
        inherit appId;
        sha256 = "96bcafe386a754a6f835a3375bbff9cf13f5e64d44579663b38c4d07c9c3c25b";
        bundle = "${pkgs.fetchurl {
          url = "https://github.com/rtr46/meikipop/releases/download/v2.0.4/meikipop.linux.x64.flatpak";
          inherit sha256;
        }}";
      }
    ];
  };

  environment.systemPackages = [ meikipop ];
}

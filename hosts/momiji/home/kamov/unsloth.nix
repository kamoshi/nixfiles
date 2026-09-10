{ rolling, ... }:
let
  unsloth = rolling.unsloth-desktop.override {
    buildFHSEnv =
      args:
      rolling.buildFHSEnv (
        args
        // {
          # PyTorch and NumPy wheels need the C++ runtime inside the FHS environment.
          targetPkgs = pkgs: args.targetPkgs pkgs ++ [ pkgs.stdenv.cc.cc.lib ];
          profile = args.profile + ''
            export LD_LIBRARY_PATH="/usr/lib:/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

            # WebKit needs glib-networking's GIO module for HTTPS requests.
            export GIO_EXTRA_MODULES="/usr/lib/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}"
          '';
        }
      );
  };
in
{
  home.packages = [ unsloth ];
}

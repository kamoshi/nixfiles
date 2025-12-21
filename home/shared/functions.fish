# Pacman orphan uninstall
if command -v pacman >/dev/null
  function orphans
    set -l orphan_pkgs (pacman -Qtdq)
    if test -n "$orphan_pkgs"
      sudo pacman -Rns $orphan_pkgs
    else
      echo "No orphan packages to remove."
    end
  end
end

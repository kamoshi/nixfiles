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

function z-lib -d "Fetch and open the first Z-Library URL from Wikipedia"
    echo "Fetching Z-Library information from Wikipedia..."

    set target_url (curl -sL "https://en.wikipedia.org/wiki/Z-Library" | \
        grep -oE 'href="https?://[^"]+"' | \
        grep -iv 'wiki' | \
        grep -v '\.onion' | \
        grep -v '\.i2p' | \
        grep -iE 'singlelogin|z-lib|zlibrary' | \
        head -n 1 | \
        sed 's/href="//;s/"//')

    if test -z "$target_url"
        echo "Error: Could not find a valid URL."
        return 1
    end

    echo "Found URL: $target_url"
    echo "Opening in browser..."

    switch (uname)
        case Darwin
            open "$target_url"
        case Linux
            xdg-open "$target_url"
        case '*'
            echo "Unsupported operating system. Please open the URL manually."
    end
end

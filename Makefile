.PHONY: default aya momiji megumu megumu-up megumu-down megumu-remote update check clean-system clean-home-manager clean-profile gc

HOSTNAME := $(firstword $(subst ., ,$(shell uname -n)))

default:
	@test -n "$(HOSTNAME)" || { echo "Could not determine hostname" >&2; exit 1; }
	@$(MAKE) --no-print-directory "$(HOSTNAME)"

aya:
	sudo darwin-rebuild switch --flake .#aya

momiji:
	sudo nixos-rebuild switch --flake .#momiji
	~/.local/share/plasma-manager/run_all.sh

megumu:
	sudo nixos-rebuild switch --flake .#megumu

megumu-up:
	rsync -avz --delete --progress . megumu:~/nix

megumu-down:
	rsync -avz --delete --progress megumu:~/nix/ .

megumu-remote:
	nix run nixpkgs#nixos-rebuild -- switch --flake .#megumu --target-host megumu --sudo --ask-sudo-password

update:
	nix flake update

check:
	nix flake check


# Cleanup

clean-system:
	sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5

clean-home-manager:
	nix-env -p ~/.local/state/nix/profiles/home-manager --delete-generations +5

clean-profile:
	nix-env -p ~/.local/state/nix/profiles/profile --delete-generations +5

gc:
	nix-collect-garbage -v

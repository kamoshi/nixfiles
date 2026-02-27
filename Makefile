.PHONY: aya momiji megumu megumu-up megumu-down megumu-remote update check

aya:
	sudo darwin-rebuild switch --flake .#aya

momiji:
	home-manager switch --flake .#momiji

megumu:
	sudo nixos-rebuild switch --flake .#megumu

megumu-up:
	rsync -avz --delete --progress . megumu:~/nix

megumu-down:
	rsync -avz --delete --progress megumu:~/nix/ .

megumu-remote:
	nix run nixpkgs#nixos-rebuild -- switch --flake .#megumu --target-host megumu --sudo --ask-sudo-password

nitori:
	home-manager switch --flake .#nitori

update:
	nix flake update

check:
	nix flake check

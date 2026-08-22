.PHONY: xray-client

xray-client:
	@sudo cat /var/lib/xray/client.json | \
		nix run nixpkgs#jq -- -r \
		'"vless://\(.uuid)@\(.address):\(.port)?encryption=none&flow=\(.flow)&security=\(.security)&sni=\(.serverName)&fp=\(.fingerprint)&pbk=\(.password)&sid=\(.shortId)&type=tcp&headerType=none&spx=\(.spiderX | @uri)#gensokyo-reality"'

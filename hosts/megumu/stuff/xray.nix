{
  inventory,
  lib,
  pkgs,
  ...
}:
let
  stateDirectory = "/var/lib/xray";
  configFile = "${stateDirectory}/config.json";
  clientFile = "${stateDirectory}/client.json";
  publicAddress = "94.130.182.219";
  listenPort = 443;
  nginxPort = 8444;
  fallbackTarget = "127.0.0.1:${toString nginxPort}";

  externalEndpointNames = [
    "forgejo"
    "fukurou"
    "immich"
    "kanidm"
    "karasu"
    "miniflux"
    "navidrome"
  ];
  tlsVirtualHostNames = [
    "_"
    "kamoshi.org"
    "hauchiwa.kamoshi.org"
    "sejm.kamoshi.org"
    "rsvp.kamoshi.org"
  ] ++ map (name: inventory.endpoints.${name}.domains.external) externalEndpointNames;
in
{
  services.xray = {
    enable = true;
    # Generated on the server at first boot so credentials never enter the
    # repository or the world-readable Nix store.
    settingsFile = configFile;
  };

  systemd.services = {
    xray-init = {
      description = "Generate persistent Xray REALITY credentials";
      requiredBy = [ "xray.service" ];
      before = [ "xray.service" ];

      path = [
        pkgs.coreutils
        pkgs.gnused
        pkgs.jq
        pkgs.openssl
      ];

      script = ''
        set -euo pipefail

        install -d -m 0700 ${stateDirectory}

        if [[ -s ${configFile} ]]; then
          config_tmp="$(mktemp ${stateDirectory}/config.json.XXXXXX)"
          jq \
            --arg listen ${lib.escapeShellArg publicAddress} \
            --argjson port ${toString listenPort} \
            --arg target ${lib.escapeShellArg fallbackTarget} '
            .inbounds[0].listen = $listen
            | .inbounds[0].port = $port
            | .inbounds[0].streamSettings.realitySettings.target = $target
            | .inbounds[0].settings.clients = (
                .inbounds[0].settings.clients
                // .inbounds[0].settings.users
              )
            | del(.inbounds[0].settings.users)
          ' \
            ${configFile} > "$config_tmp"
          install -m 0600 "$config_tmp" ${configFile}
          rm -f "$config_tmp"

          if [[ -s ${clientFile} ]]; then
            client_tmp="$(mktemp ${stateDirectory}/client.json.XXXXXX)"
            jq --argjson port ${toString listenPort} '
              .port = $port
              | .spiderX = (
                  .spiderX
                  // ("/favicon.ico?ref=" + .shortId)
                )
            ' \
              ${clientFile} > "$client_tmp"
            install -m 0600 "$client_tmp" ${clientFile}
            rm -f "$client_tmp"
          fi

          exit 0
        fi

        key_pair="$(${pkgs.xray}/bin/xray x25519)"
        private_key="$(printf '%s\n' "$key_pair" | sed -n 's/^PrivateKey: //p')"
        public_key="$(printf '%s\n' "$key_pair" | sed -n -e 's/^Password (PublicKey): //p' -e 's/^Password: //p' -e 's/^PublicKey: //p')"
        uuid="$(${pkgs.xray}/bin/xray uuid)"
        short_id="$(openssl rand -hex 8)"

        if [[ -z "$private_key" || -z "$public_key" || -z "$uuid" ]]; then
          echo "Failed to generate Xray credentials" >&2
          exit 1
        fi

        jq -n \
          --arg privateKey "$private_key" \
          --arg uuid "$uuid" \
          --arg shortId "$short_id" \
          '{
            log: { loglevel: "warning" },
            inbounds: [{
              tag: "vless-reality",
              listen: "${publicAddress}",
              port: ${toString listenPort},
              protocol: "vless",
              settings: {
                clients: [{
                  id: $uuid,
                  flow: "xtls-rprx-vision"
                }],
                decryption: "none"
              },
              streamSettings: {
                method: "raw",
                security: "reality",
                realitySettings: {
                  show: false,
                  target: "${fallbackTarget}",
                  xver: 0,
                  serverNames: ["kamoshi.org"],
                  privateKey: $privateKey,
                  shortIds: [$shortId]
                }
              }
            }],
            outbounds: [
              { protocol: "freedom", tag: "direct" },
              { protocol: "blackhole", tag: "blocked" }
            ]
          }' > ${configFile}

        jq -n \
          --arg address "${publicAddress}" \
          --arg password "$public_key" \
          --arg uuid "$uuid" \
          --arg shortId "$short_id" \
          '{
            address: $address,
            port: ${toString listenPort},
            protocol: "vless",
            uuid: $uuid,
            flow: "xtls-rprx-vision",
            transport: "raw",
            security: "reality",
            serverName: "kamoshi.org",
            fingerprint: "chrome",
            password: $password,
            shortId: $shortId,
            spiderX: ("/favicon.ico?ref=" + $shortId)
          }' > ${clientFile}

        chmod 0600 ${configFile} ${clientFile}
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
      };
    };

    xray = {
      requires = [ "xray-init.service" ];
      after = [ "xray-init.service" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ listenPort ];

  # Xray owns public TLS port 443. Connections that are not authenticated
  # REALITY traffic are transparently passed to nginx on loopback, where the
  # original SNI still selects the correct virtual host.
  services.nginx.virtualHosts = lib.genAttrs tlsVirtualHostNames (_: {
    listen = lib.mkForce [
      {
        addr = "[::]";
        port = 80;
        ssl = false;
      }
      {
        addr = publicAddress;
        port = 80;
        ssl = false;
      }
      {
        addr = "127.0.0.1";
        port = nginxPort;
        ssl = true;
      }
    ];
  });
}

{
  inventory,
  lib,
  ...
}:
let
  containerName = "xray";
  containerInterface = "ve-${containerName}";
  hostAddress = "10.233.0.1";
  containerAddress = "10.233.0.2";
  publicAddress = "94.130.182.219";
  publicPort = 443;
  xrayPort = 8443;
  nginxPort = 8444;
  stateDirectory = "/var/lib/xray";
  configFile = "${stateDirectory}/config.json";
  clientFile = "${stateDirectory}/client.json";
  fallbackTarget = "${hostAddress}:${toString nginxPort}";

  # Shared by first boot and migration; policy changes also replace saved policy.
  outboundPolicy = {
    outbounds = [
      {
        protocol = "blackhole";
        tag = "blocked";
      }
      {
        protocol = "freedom";
        tag = "direct";
        settings.domainStrategy = "UseIPv4";
      }
    ];
    routing = {
      domainStrategy = "IPOnDemand";
      rules = [
        # REALITY's own fallback bypasses outbound routing. Proxy requests
        # must never reach its trusted PROXY-protocol listener, even after
        # DNS rebinding. This also excludes public TCP destinations on 8444.
        {
          type = "field";
          network = "tcp";
          port = toString nginxPort;
          outboundTag = "blocked";
        }
        {
          type = "field";
          ip = [ "geoip:private" ];
          outboundTag = "blocked";
        }
        {
          type = "field";
          network = "tcp,udp";
          outboundTag = "direct";
        }
      ];
    };
  };
  policyArgument = lib.escapeShellArg (builtins.toJSON outboundPolicy);
  fallbackRule = ''iifname "${containerInterface}" ip saddr ${containerAddress} ip daddr ${hostAddress} tcp dport ${toString nginxPort} accept'';

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
  ]
  ++ map (name: inventory.endpoints.${name}.domains.external) externalEndpointNames;
in
{
  # Keep credentials outside the Nix store and preserve them across container
  # rebuilds. The id-mapped bind mount makes this usable with privateUsers.
  systemd.tmpfiles.rules = [
    "d ${stateDirectory} 0700 root root -"
  ];

  containers.${containerName} = {
    autoStart = true;
    privateNetwork = true;
    privateUsers = "pick";
    inherit hostAddress;
    localAddress = containerAddress;
    # NixOS adds idmap to its own mounts, but not to bindMounts entries.
    # Map host root to container root without changing credential ownership.
    extraFlags = [ "--bind=${stateDirectory}:${stateDirectory}:idmap" ];

    config =
      { lib, pkgs, ... }:
      {
        system.stateVersion = "26.05";
        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [ xrayPort ];
          };
          # Deliberately do not give the container IPv6 connectivity. This
          # keeps the host policy small and fail-closed for IPv6 destinations.
          enableIPv6 = false;
          # The host resolver listens on host loopback, which is not reachable
          # from this private network namespace.
          useHostResolvConf = false;
          nameservers = [
            "1.1.1.1"
            "9.9.9.9"
          ];
        };

        services.xray = {
          enable = true;
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

              umask 077
              install -d -m 0700 ${stateDirectory}
              config_tmp="$(mktemp ${stateDirectory}/config.json.XXXXXX)"
              client_tmp="$(mktemp ${stateDirectory}/client.json.XXXXXX)"
              trap 'rm -f "$config_tmp" "$client_tmp"' EXIT

              if [[ -s ${configFile} ]]; then
                jq \
                  --argjson policy ${policyArgument} \
                  --arg target ${lib.escapeShellArg fallbackTarget} \
                  --argjson port ${toString xrayPort} '
                    .inbounds[0].listen = "0.0.0.0"
                    | .inbounds[0].port = $port
                    | .inbounds[0].streamSettings.network = "raw"
                    | del(.inbounds[0].streamSettings.method)
                    | .inbounds[0].streamSettings.realitySettings.target = $target
                    | .inbounds[0].streamSettings.realitySettings.xver = 1
                    | .inbounds[0].settings.clients = (
                        .inbounds[0].settings.clients
                        // .inbounds[0].settings.users
                      )
                    | del(.inbounds[0].settings.users)
                    | . + $policy
                  ' ${configFile} > "$config_tmp"
                mv -f "$config_tmp" ${configFile}

                if [[ -s ${clientFile} ]]; then
                  jq --argjson port ${toString publicPort} '
                    .port = $port
                    | .spiderX = (
                        .spiderX
                        // ("/favicon.ico?ref=" + .shortId)
                      )
                  ' ${clientFile} > "$client_tmp"
                  mv -f "$client_tmp" ${clientFile}
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
                --argjson policy ${policyArgument} \
                --arg privateKey "$private_key" \
                --arg uuid "$uuid" \
                --arg shortId "$short_id" \
                '{
                  log: { loglevel: "warning" },
                  inbounds: [{
                    tag: "vless-reality",
                    listen: "0.0.0.0",
                    port: ${toString xrayPort},
                    protocol: "vless",
                    settings: {
                      clients: [{
                        id: $uuid,
                        flow: "xtls-rprx-vision"
                      }],
                      decryption: "none"
                    },
                    streamSettings: {
                      network: "raw",
                      security: "reality",
                      realitySettings: {
                        show: false,
                        target: "${fallbackTarget}",
                        xver: 1,
                        serverNames: ["kamoshi.org"],
                        privateKey: $privateKey,
                        shortIds: [$shortId]
                      }
                    }
                  }]
                } + $policy' > "$config_tmp"

              jq -n \
                --arg address "${publicAddress}" \
                --arg password "$public_key" \
                --arg uuid "$uuid" \
                --arg shortId "$short_id" \
                '{
                  address: $address,
                  port: ${toString publicPort},
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
                }' > "$client_tmp"

              # Commit the authoritative server configuration last. Renames
              # prevent interrupted writes from leaving truncated credentials.
              mv -f "$client_tmp" ${clientFile}
              mv -f "$config_tmp" ${configFile}
            '';

            serviceConfig = {
              Type = "oneshot";
              UMask = "0077";
            };
          };

          xray = {
            requires = [ "xray-init.service" ];
            after = [ "xray-init.service" ];
            unitConfig = {
              StartLimitIntervalSec = 60;
              StartLimitBurst = 5;
            };
            serviceConfig = {
              Restart = "on-failure";
              RestartSec = "5s";
              AmbientCapabilities = lib.mkForce "";
              CapabilityBoundingSet = lib.mkForce "";
              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              MemoryMax = "512M";
              NoNewPrivileges = true;
              PrivateDevices = true;
              PrivateTmp = true;
              ProtectClock = true;
              ProtectControlGroups = true;
              ProtectHome = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectSystem = "strict";
              RestrictAddressFamilies = [
                "AF_INET"
                "AF_UNIX"
              ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              SystemCallArchitectures = "native";
              SystemCallFilter = [
                "@system-service"
                "~@privileged"
                "~@resources"
              ];
              TasksMax = 512;
            };
          };
        };
      };
  };

  # Publish the container's unprivileged listener on the public TLS port and
  # masquerade only traffic sourced by its veth.
  networking.nat = {
    internalInterfaces = [ containerInterface ];
    forwardPorts = [
      {
        sourcePort = publicPort;
        destination = "${containerAddress}:${toString xrayPort}";
        proto = "tcp";
      }
    ];
  };

  # This table is independent of Xray and of the container. Even arbitrary
  # code execution as the Xray UID cannot change these host-owned rules.
  # An accept in the isolation table does not bypass the normal input chain.
  networking.firewall.extraInputRules = fallbackRule;
  networking.nftables.enable = true;
  networking.nftables.tables.xray-isolation = {
    family = "inet";
    content = ''
      chain xray-input {
        type filter hook input priority -10; policy accept;

        ${fallbackRule}
        iifname "${containerInterface}" drop
      }

      chain xray-forward {
        type filter hook forward priority -10; policy accept;

        iifname "${containerInterface}" ip saddr != ${containerAddress} drop
        iifname "${containerInterface}" ip daddr ${publicAddress} drop
        iifname "${containerInterface}" tcp dport { 25, 465, 587 } drop
        iifname "${containerInterface}" ip daddr {
          0.0.0.0/8,
          10.0.0.0/8,
          100.64.0.0/10,
          127.0.0.0/8,
          169.254.0.0/16,
          172.16.0.0/12,
          192.0.0.0/24,
          192.0.2.0/24,
          192.168.0.0/16,
          198.18.0.0/15,
          198.51.100.0/24,
          203.0.113.0/24,
          224.0.0.0/4,
          240.0.0.0/4
        } drop
        iifname "${containerInterface}" meta nfproto ipv6 drop
      }
    '';
  };

  # Do not expose the container until both the host firewall and the only
  # permitted host-side destination are ready.
  systemd.services."container@${containerName}" = {
    unitConfig.RequiresMountsFor = [ stateDirectory ];
    requires = [
      "nftables.service"
      "nginx.service"
    ];
    after = [
      "nftables.service"
      "nginx.service"
    ];
  };

  # Xray owns public TCP 443. Non-REALITY traffic reaches this single host
  # socket with PROXY protocol, retaining the original client address.
  # Xray is a trusted ingress: a compromised process can forge these addresses.
  # Applications must authenticate independently of client IP.
  services.nginx = {
    appendHttpConfig = ''
      set_real_ip_from ${containerAddress};
      real_ip_header proxy_protocol;
    '';
    virtualHosts = lib.genAttrs tlsVirtualHostNames (_: {
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
          addr = hostAddress;
          port = nginxPort;
          ssl = true;
          proxyProtocol = true;
        }
      ];
    });
  };
}

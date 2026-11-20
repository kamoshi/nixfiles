{ ... }:

{
  systemd.services.set-cpu-rapl-limits = {
    description = "Set Intel RAPL CPU power limits";

    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    before = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    # Default limits
    # long_term: 65000000 µW
    # short_term: 81250000 µW
    script = ''
      R=/sys/class/powercap/intel-rapl:0

      test -w "$R/constraint_0_power_limit_uw"
      test -w "$R/constraint_1_power_limit_uw"

      test "$(cat "$R/constraint_0_name")" = "long_term"
      test "$(cat "$R/constraint_1_name")" = "short_term"

      echo 45000000 > "$R/constraint_0_power_limit_uw"
      echo 65000000 > "$R/constraint_1_power_limit_uw"
    '';
  };
}

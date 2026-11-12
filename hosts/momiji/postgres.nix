{ ... }:
{
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "crime_report_db"
    ];
  };
}

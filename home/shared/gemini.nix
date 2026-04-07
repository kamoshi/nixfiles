{ nightly, ... }:
let
  gemini-cli-034 = nightly.gemini-cli.overrideAttrs (
    old:
    let
      # Pinned to 0.34.0 because v0.35.3 reportedly has an extreme performance
      # regression; see google-gemini/gemini-cli#24294.
      version = "0.34.0";
      src = nightly.fetchFromGitHub {
        owner = "google-gemini";
        repo = "gemini-cli";
        tag = "v${version}";
        hash = "sha256-/HmcLnScZ2pmzGnRLsNHoqrakyt++1fCv/P2IeE8pGo=";
      };
    in
    {
      inherit version;
      inherit src;

      npmDepsHash = nightly.lib.fakeHash;
      npmDeps = nightly.fetchNpmDeps {
        inherit src;
        hash = "sha256-3Y9QJC4dqvnCH3qFSsvFMK+XtHnZyYPBP1voLpHpHA4=";
      };
    }
  );
in
{
  home.packages = [
    gemini-cli-034
  ];
}

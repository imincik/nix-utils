{
  description = "nix-utils";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          hydra-build-status = pkgs.python3Packages.buildPythonApplication {
            pname = "hydra-build-status";
            version = "0-unstable";
            format = "other";

            src = ./.;

            dependencies = with pkgs.python3Packages; [
              requests
              beautifulsoup4
            ];

            dontBuild = true;
            dontUnpack = true;

            installPhase = ''
              runHook preInstall
              install -D ${./hydra-build-status.py} $out/bin/hydra-build-status
              runHook postInstall
            '';

            meta = {
              description = "Report last Hydra build status for given platforms and packages";
              homepage = "https://github.com/imincik/nix-utils";
              license = pkgs.lib.licenses.mit;
              mainProgram = "hydra-build-status";
            };
          };

          package-versions = pkgs.python3Packages.buildPythonApplication {
            pname = "package-versions";
            version = "0-unstable";
            format = "other";

            src = ./.;

            dontBuild = true;
            dontUnpack = true;

            installPhase = ''
              runHook preInstall
              install -D ${./package-versions.py} $out/bin/package-versions
              runHook postInstall
            '';

            meta = {
              description = "Report packages versions and backport status";
              homepage = "https://github.com/imincik/nix-utils";
              license = pkgs.lib.licenses.mit;
              mainProgram = "package-versions";
            };
          };
        }
      );
    };
}

{
  description = "Go-to nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
  };

	outputs = { self, nixpkgs, flake-utils }:
	  flake-utils.lib.eachDefaultSystem (system:
	    let pkgs = nixpkgs.legacyPackages.${system}; in
	    {
	      packages = rec {
					WIP = pkgs.stdenv.mkDerivation {
						pname = "WIP";

						src = ./.;

						nativeBuildInputs = with pkgs; [ ];

						buildInputs = with pkgs; [ ];

					};
	        default = WIP;
	      };
	      apps = rec {
	        WIP = flake-utils.lib.mkApp { drv = self.packages.${system}.WIP; };
	        default = WIP;
	      };
				# to use the interactive builder, type in "ib"
				devShell = with pkgs; mkShell rec
				{
					interactiveBuilder = writeScriptBin "interactiveBuilder.bash" ''
						SHELL=$(which bash)
						export SHELL

						# make sure that script is sourced
						(return 0 2>/dev/null) && sourced=1 || sourced=0
						if [ "$sourced" -eq 0 ]; then
						    echo -e "ERROR, this script must be sourced (run 'source $0')."
						    exit 1
						fi

						# make sure that script is sourced from nix shell
						(type -t genericBuild &>/dev/null) && in_nix_shell=1 || in_nix_shell=0
						if [ "$in_nix_shell" -eq 0 ]; then
						    echo -e "ERROR, this script must be sourced from nix shell environment (run 'nix develop nixpkgs#<PACKAGE>')."
						    return 1
						fi

						# phases detection taken from
						# https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/generic/setup.sh
						all_phases="''${prePhases[*]:-} unpackPhase patchPhase ''${preConfigurePhases[*]:-} \
						    configurePhase ''${preBuildPhases[*]:-} buildPhase checkPhase \
						    ''${preInstallPhases[*]:-} installPhase ''${preFixupPhases[*]:-} fixupPhase installCheckPhase \
						    ''${preDistPhases[*]:-} distPhase ''${postPhases[*]:-}";

						# run phases
						for phase in ''${all_phases[*]}; do
						    phases_pretty=$(echo "''${all_phases[*]}" | sed "s|$phase|**$phase**|g" | tr -s '[:blank:]')
						    echo -e "\n>>> Phase:   $phases_pretty"
						    # TODO: change command to runPhase $phase once 23.11 is released and 23.05 is not longer supported
						    # https://discourse.nixos.org/t/nix-build-phases-run-nix-build-phases-interactively/36090/4
						    echo ">>> Command:  runPhase $phase"
						    echo ">>> Press ENTER to run, CTRL-C to exit"
						    read

						    phases=runPhase $phase 
						done	
					'';

					shellHook = ''
						alias ib='source interactiveBuilder.bash'
					'';
					

					buildInputs = self.packages.${system}.default.buildInputs
					++ self.packages.${system}.default.nativeBuildInputs
					++ [
						interactiveBuilder
					];
				};
	    }
	  );
}


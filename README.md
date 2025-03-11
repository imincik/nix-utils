# nix-utils

* **nix-develop-interactive.bash:** interactively run nix build phases
* **hydra-build-status.py:** report last Hydra build status for given packages
* **maintainer-packages.nix:** list packages maintained by a person


## Build status

[![Linux packages ](https://github.com/imincik/nix-utils/actions/workflows/hydra-build-status-linux.yml/badge.svg)](https://github.com/imincik/nix-utils/actions/workflows/hydra-build-status-linux.yml)
[![Darwin packages](https://github.com/imincik/nix-utils/actions/workflows/hydra-build-status-darwin.yml/badge.svg)](https://github.com/imincik/nix-utils/actions/workflows/hydra-build-status-darwin.yml)


## Automatic updates (nixpkgs-update bot)

* [Update queue](https://nixpkgs-update-logs.nix-community.org/~supervisor/queue.html)
* [Update logs](https://nixpkgs-update-logs.nix-community.org/)


## Reports

* [Outdated packages](https://repology.org/projects/?maintainer=ivan.mincik%40gmail.com&inrepo=nix_unstable&outdated=1)
* [Vulnerable packages](https://repology.org/projects/?maintainer=ivan.mincik%40gmail.com&inrepo=nix_unstable&vulnerable=on)


## Notes

* Convert new line separated list of packages to JSON file suitable for
  `hydra-build-status.py`
  ```
  cat packages.txt | jq -s --raw-input '. | split("\n")' > packages.json
  hydra-build-status.py -f ./packages.json -p x86_64-linux
  ```

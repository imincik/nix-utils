# nix-utils

## nix-build-phases.bash

Interactively run nix build phases.
This script must be sourced in Nix development shell environent !

* Create development directory
```bash
mkdir dev; cd dev
```

* Enter nix development shell
```bash
nix develop nixpkgs#<PACKAGE>
```

* Launch script by sourcing it
```bash
. ../nix-build-phases.bash
```


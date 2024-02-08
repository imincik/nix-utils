#!/usr/bin/env bash

# Interactively run Nix build phases.
# This script must be sourced in Nix development shell environent !

# USAGE: 
# mkdir dev; cd dev
# nix develop nixpkgs#<PACKAGE>
# source nix-develop-interactive.bash


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
all_phases="${prePhases[*]:-} unpackPhase patchPhase ${preConfigurePhases[*]:-} \
    configurePhase ${preBuildPhases[*]:-} buildPhase checkPhase \
    ${preInstallPhases[*]:-} installPhase ${preFixupPhases[*]:-} fixupPhase installCheckPhase \
    ${preDistPhases[*]:-} distPhase ${postPhases[*]:-}";

# run phases
for phase in ${all_phases[*]}; do
    phases_pretty=$(echo "${all_phases[*]}" | sed "s|$phase|**$phase**|g" | tr -s '[:blank:]')
    echo -e "\n>>> Phase:   $phases_pretty"
    # TODO: change command to runPhase $phase once 23.11 is released and 23.05 is not longer supported
    # https://discourse.nixos.org/t/nix-build-phases-run-nix-build-phases-interactively/36090/4
    echo ">>> Command:  phases=$phase genericBuild"
    echo ">>> Press ENTER to run, CTRL-C to exit"
    read

    phases=$phase genericBuild
done

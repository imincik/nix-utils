# List nixpkgs packages maintained by a team.
#
# USAGE:
# nix eval --json -f team-packages.nix packages

{
  pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/master.tar.gz") {
    config.allowBroken = true;
    config.allowUnfree = true;
  },

  team ? "geospatial",

  showBroken ? true, # show broken packages
}:

let
  inherit (pkgs.lib)
    attrNames
    concatMap
    isAttrs
    isDerivation
    ;

  myTeam = pkgs.lib.teams.${team};

  isMaintainedByTeam =
    pkg:
    let
      result = builtins.tryEval (builtins.elem myTeam (pkg.meta.teams or [ ]));
    in
    if result.success then result.value else false;

  isDerivationRobust =
    pkg:
    let
      result = builtins.tryEval (isDerivation pkg);
    in
    if result.success then result.value else false;

  brokenFilter =
    pkg:
    let
      isBroken = pkg.meta.broken or false;
    in
    if showBroken then
      true
    else if isBroken == false then
      true
    else
      false;

  isPkgSet =
    pkg:
    let
      result = builtins.tryEval ((isAttrs pkg) && (pkg.recurseForDerivations or false));
    in
    if result.success then result.value else false;

  recursePackageSet =
    pkgSetName: pkgs:
    concatMap (
      name:
      let
        pkg = pkgs.${name};
        fullName = if pkgSetName != null then pkgSetName + "." + name else name;
      in
      if isDerivationRobust pkg then
        if isMaintainedByTeam pkg && brokenFilter pkg then [ fullName ] else [ ]
      else if isPkgSet pkg then
        recursePackageSet fullName pkg
      else
        [ ]
    ) (attrNames pkgs);

in
{
  packages = recursePackageSet null pkgs;
}

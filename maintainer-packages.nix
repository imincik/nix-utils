# List packages maintained by a person.

# USAGE:
# nix eval --json -f maintainer-query.nix packages \
# | jq '[.. | objects | select(has("name")) | .name]'


{ pkgs ? import
    (fetchTarball "https://github.com/NixOS/nixpkgs/archive/master.tar.gz")
    { config.allowBroken = true; config.allowUnfree = true; }

, maintainer ? "imincik"
}:

let
  myMaintainer = pkgs.lib.maintainers.${maintainer};

  isMaintainedBy = pkg:
    builtins.elem myMaintainer (pkg.meta.maintainers or [ ]);

  isDerivationRobust = pkg:
    let
      result = builtins.tryEval (
        pkgs.lib.isDerivation pkg
      );
    in
    if result.success then result.value
    else false;

  isPkgSet = pkg:
    let
      result = builtins.tryEval (
        (builtins.isAttrs pkg) && (pkg.recurseForDerivations or false)
      );
    in
    if result.success then result.value
    else false;

  recursePackageSet = pkgSetName: pkgs:
    builtins.mapAttrs
      (name: pkg:
        if isDerivationRobust pkg then
          if isMaintainedBy pkg then
            { name = "${if pkgSetName != null then pkgSetName + "." + name else name}"; } else null
        else if isPkgSet pkg then
          recursePackageSet name pkg
        else null
      )
      pkgs;

in
{
  packages =
    builtins.attrValues
      (pkgs.lib.filterAttrsRecursive (n: v: v != { })
        (pkgs.lib.filterAttrsRecursive (n: v: v != null) (recursePackageSet null pkgs)));
}

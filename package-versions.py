#!/usr/bin/env python

# Get package versions of two nixpkgs branches (e.g. master and stable
# release) and report whether each package is a backport candidate.
#
# A package qualifies for backport when master and the stable branch share the
# same major.minor version and master's version is higher than stable's.

# USAGE:
#  nix eval --json -f team-packages.nix packages > <PACKAGES-FILE>.json
#
# package-versions.py --file <PACKAGES-FILE.json> --branches=<MASTER-REF>,<STABLE-REF>

import sys
from getopt import getopt

import json
import subprocess


STABLE_VERSION = "release-26.05"

opts, args = getopt(sys.argv[1:], "f:b:", ["file=", "branches="])

pkgs_file = "packages.json"
branches = ["nixpkgs", "nixpkgs/" + STABLE_VERSION]
for opt, arg in opts:
    if opt in ["-f", "--file"]:
        pkgs_file = arg

    elif opt in ["-b", "--branches"]:
        branches = arg.split(",")

master_branch, stable_branch = branches

with open(pkgs_file, "r") as file:
    pkgs = json.load(file)


def get_version(branch, pkg):
    result = subprocess.run(
        ["nix", "eval", "--json", f"{branch}#{pkg}.version"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return "N/A"
    return json.loads(result.stdout)


def major_minor(version):
    parts = version.split(".")
    return tuple(parts[:2])


def version_key(version):
    return [int(part) if part.isdigit() else part for part in version.split(".")]


def is_lower(version_a, version_b):
    return version_key(version_a) < version_key(version_b)


def print_header():
    print(
        "| {f1: <50} | {f2: <25} | {f3: <25} | {f4: <10} |".format(
            f1="PACKAGE", f2=master_branch.upper(), f3=stable_branch.upper(), f4="BACKPORT"
        )
    )
    print("| {sep: <50} | {sep: <25} | {sep: <25} | {sep: <10} |".format(sep=10 * "-"))


print_header()

for pkg in pkgs:
    master_version = get_version(master_branch, pkg)
    stable_version = get_version(stable_branch, pkg)

    stable_is_lower = (
        master_version != "N/A"
        and stable_version != "N/A"
        and is_lower(stable_version, master_version)
    )

    can_backport = (
        stable_is_lower
        and major_minor(master_version) == major_minor(stable_version)
    )
    backport = "Yes" if can_backport else "No"

    stable_display = stable_version
    if stable_is_lower:
        stable_display = f"{stable_version} [-]"

    print(
        f"| {pkg: <50} | {master_version: <25} | {stable_display: <25} | {backport: <10} |"
    )

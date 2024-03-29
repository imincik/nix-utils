#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3Packages.requests python3Packages.beautifulsoup4 -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/7790e078f8979a9fcd543f9a47427eeaba38f268.tar.gz

# Report last Hydra build status for given platforms and packages. All supported
# platforms will be checked, if no platform is specified. Fail with exit code 1
# if status of any checked package is not good.

# USAGE:
# hydra-build-status.py --platforms=[PLATFORM,PLATFORM,...] <PACKAGE> <PACKAGE> ...

import sys
from getopt import getopt

import requests
import time
from bs4 import BeautifulSoup


opts, args = getopt(sys.argv[1:], "p:", ["platforms="])

# list of platforms
platforms = ["x86_64-linux", "aarch64-linux", "x86_64-darwin", "aarch64-darwin"]
for option, argument in opts:
    if option in ["-p", "--platforms"]:
        platforms = argument.split(",")

# list of packages
pkgs = args


exit_code = 0
for platform in platforms:
    print(f"\n### PLATFORM: {platform} ###")
    for pkg in pkgs:
        url = f"https://hydra.nixos.org/job/nixpkgs/trunk/{pkg}.{platform}/all"
        page = requests.get(url)

        soup = BeautifulSoup(page.content, "html.parser")

        results_table = soup.find("table", class_="table")
        build_results = results_table.find_all("tr")

        if len(build_results) > 1:
            build_result = build_results[1].find_all("td")
            build_status = build_result[0].img["alt"]
        else:
            build_status = "No data"

        print(f"{pkg : <50} {build_status : <20} URL: {url : <50}")

        if build_status not in ["Succeeded", "Cancelled", "No data"]:
            exit_code = 1

        time.sleep(1)  # don't overload Hydra

sys.exit(exit_code)

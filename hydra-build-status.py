#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3Packages.requests python3Packages.beautifulsoup4 -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/7790e078f8979a9fcd543f9a47427eeaba38f268.tar.gz 

# Report last Hydra build status for given packages. Fail with exit code 1 if
# status of any given package is not success.

# USAGE:
# hydra-build-status.py <PACKAGE> <PACKAGE> ...

import sys

import requests
from bs4 import BeautifulSoup


pkgs = sys.argv[1:]


exit_code = 0
for pkg in pkgs:
    URL = f"https://hydra.nixos.org/job/nixpkgs/trunk/{pkg}.x86_64-linux/all"
    page = requests.get(URL)

    soup = BeautifulSoup(page.content, "html.parser")

    results_table = soup.find("table", class_="table")
    build_results = results_table.find_all("tr")
    build_result = build_results[1].find_all("td")
    build_status = build_result[0].img["alt"]

    print(f"{pkg : <50} {build_status : <20} URL: {URL : <50}")

    if build_status != "Succeeded": exit_code = 1

sys.exit(exit_code)

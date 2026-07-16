#!/usr/bin/env python

# Report last Hydra build status for given platforms and packages. All supported
# platforms will be checked, if no platform is specified. Fail with exit code 1
# if status of any checked package is not good.

# USAGE:
# hydra-build-status.py --file <PACKAGES-FILE.json> --platforms=[PLATFORM,PLATFORM,...] [--failed-only]

import sys
from getopt import getopt

import json
import requests
import time
import datetime
from bs4 import BeautifulSoup

USER_AGENT="hydra-build-status.py; Nix Geospatial team; Ivan Mincik (@imincik)"
HYDRA_URL = "https://hydra.nixos.org"
OK_STATUSES = ["Succeeded", "Cancelled", "No data", "No recent data"]

opts, args = getopt(sys.argv[1:], "f:p:x", ["file=", "platforms=", "failed-only"])

# list of platforms
platforms = ["x86_64-linux", "aarch64-linux", "x86_64-darwin", "aarch64-darwin"]
failed_only = False
for opt, arg in opts:
    if opt in ["-p", "--platforms"]:
        platforms = arg.split(",")

    elif opt in ["-f", "--file"]:
        pkgs_file = arg

    elif opt in ["-x", "--failed-only"]:
        failed_only = True

# list of packages
with open(pkgs_file, 'r') as file:
    pkgs = json.load(file)


def print_header(platform):
    print(f"\n### PLATFORM: {platform}\n")
    print("| {f1: <50} | {f2: <20} | {f3: <80} |".format(f1="PACKAGE", f2="STATUS", f3="URL"))
    print("| {sep: <50} | {sep: <20} | {sep: <80} |".format(sep=20*"-"))


exit_code = 0
for platform in platforms:
    header_printed = False

    if not failed_only:
        print_header(platform)
        header_printed = True

    for pkg in pkgs:
        headers = {'User-Agent': USER_AGENT}
        url = f"{HYDRA_URL}/job/nixpkgs/trunk/{pkg}.{platform}/all"
        page = requests.get(url, headers=headers)

        soup = BeautifulSoup(page.content, "html.parser")

        results_table = soup.find("table", class_="table")
        build_results = results_table.find_all("tr")

        if len(build_results) > 1:
            build_result = build_results[1].find_all("td")

            now_time = datetime.datetime.now()
            build_time = datetime.datetime.fromtimestamp(int(build_result[2].time["data-timestamp"]))

            # Ignore too old builds.
            # For example: https://hydra.nixos.org/job/nixpkgs/trunk/qgis.x86_64-darwin/all
            if (now_time - build_time).days < 365:
                build_status = build_result[0].img["alt"]
            else:
                build_status = "No recent data"
        else:
            build_status = "No data"

        is_ok = build_status in OK_STATUSES

        if not is_ok:
            exit_code = 1

        if not failed_only or not is_ok:
            if not header_printed:
                print_header(platform)
                header_printed = True

            print(f"| {pkg: <50} | {build_status: <20} | {url: <80} |")

        time.sleep(1)  # don't overload Hydra

sys.exit(exit_code)

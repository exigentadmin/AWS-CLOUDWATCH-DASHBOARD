#!/usr/bin/env python3
"""
Terraform external data source: lists all Amazon Connect instances in a region.
Reads {"region": "<name>"} from stdin, writes {"instances": "<json>"} to stdout.
"""
import json
import subprocess
import sys


def main():
    query = json.load(sys.stdin)
    region = query["region"]

    proc = subprocess.run(
        ["aws", "connect", "list-instances", "--region", region, "--output", "json"],
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        print(
            f"aws connect list-instances failed in {region}: {proc.stderr}",
            file=sys.stderr,
        )
        sys.exit(1)

    data = json.loads(proc.stdout)

    # Skip instances with no alias — they cannot be meaningfully named in a dashboard.
    instances = {
        inst["InstanceAlias"]: inst["Id"]
        for inst in data.get("InstanceSummaryList", [])
        if inst.get("InstanceAlias")
    }

    print(json.dumps({"instances": json.dumps(instances)}))


if __name__ == "__main__":
    main()

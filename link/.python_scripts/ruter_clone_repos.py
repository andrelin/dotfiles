#!/usr/bin/python
import sys
import os
import stashy
from pathlib import Path

stash = stashy.connect(
    "https://stash.ruter.no/", 
    "kh1334",
    "XXXXXXXXXXXXXXXXXXXXXXXX")

repos = {
    'RDPIN',
    'RDPMON',
    'RDPMQS',
    'RDPSIR',
    'RDP',
    'TAAS'
    }

root_dir = "/Users/andrelin/src/ruter/"

for repo_to_clone in repos:
    if os.path.exists(root_dir + repo_to_clone):
        os.chdir(root_dir + repo_to_clone)
        os.system("eval 'find . -type d -depth 1 -exec git --git-dir={}/.git --work-tree=$PWD/{} pull origin master --prune \\;'")
    else:
        Path(root_dir + repo_to_clone).mkdir()

    for repo in stash.projects[repo_to_clone].repos.list():
        for url in repo["links"]["clone"]:
            if url["name"] == "http":
                print(url)
                git_command = "git clone " + url["href"]
                os.chdir(root_dir + repo_to_clone)
                print(git_command)
                os.system(git_command)
                break

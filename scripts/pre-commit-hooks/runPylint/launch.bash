#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

repo_basedir=$(git rev-parse --show-toplevel)
script_dir=$(dirname "$0")

if [ ! -f "$script_dir/.venv/bin/activate" ] ; then
    echo "Installing and creating venv.."
    pip3 install virtualenv >/dev/null 2>&1
    virtualenv -p python3 "$script_dir"/.venv >/dev/null 2>&1
fi

# shellcheck disable=1091,1090
source "$script_dir"/.venv/bin/activate
python -m pip install -r "$script_dir"/requirements.txt >/dev/null 2>&1

pylint --rcfile="$repo_basedir"/.pylintrc "$repo_basedir"

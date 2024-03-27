#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

set -x

repo_basedir=$(git rev-parse --show-toplevel)
script_dir=$(dirname "$0")

if [ ! -f "$script_dir/.venv/bin/activate" ] ; then
    echo "Installing and creating venv.."
    pip3 install virtualenv
    virtualenv -p python3 "$script_dir"/.venv
fi

# shellcheck disable=1091,1090
source "$script_dir"/.venv/bin/activate
python -m pip install -r "$script_dir"/requirements.txt

pylint --rcfile="$repo_basedir"/.pylintrc "$repo_basedir"

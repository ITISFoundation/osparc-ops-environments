#!/bin/bash
#

set -o nounset
set -o pipefail
IFS=$'\n\t'

if [ -f ".venv/bin/activate" ] ; then
	sleep 0
else
    echo "Installing and creating venv.."
    pip3 install virtualenv >/dev/null 2>&1
    virtualenv -p python3 .venv >/dev/null 2>&1
fi
set -o allexport
source .venv/bin/activate
pip install -r requirements.txt
python pull_images.py $1
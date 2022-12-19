#!/bin/bash
#

set -o nounset
set -o pipefail
IFS=$'\n\t'

# For pre-commit hook
# via https://stackoverflow.com/questions/3349105/how-can-i-set-the-current-working-directory-to-the-directory-of-the-script-in-ba
cd "$(dirname "$0")" || exit 1
if [ -f ".venv/bin/activate" ] ; then
	sleep 0
else
    echo "Installing and creating venv.."
    pip3 install virtualenv >/dev/null 2>&1
    virtualenv -p python3 .venv >/dev/null 2>&1
fi
# shellcheck disable=1091
source .venv/bin/activate
python -m pip install -r requirements.txt >/dev/null 2>&1
for i in "$@"; do
  for target in master local dalco public aws vagrant; do
    cd "$(dirname "$0")" || exit 1
    cd ../../../"$(dirname "$i")" && bash -c "make compose-$target >/dev/null 2>&1"
  done
done

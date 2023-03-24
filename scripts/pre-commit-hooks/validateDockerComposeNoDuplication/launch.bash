#!/bin/bash
#

set -o nounset
set -o pipefail
IFS=$'\n\t'

# For pre-commit hook
# via https://stackoverflow.com/questions/3349105/how-can-i-set-the-current-working-directory-to-the-directory-of-the-script-in-ba
cd "$(dirname "$0")" || exit
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
  # assert file not empty via https://www.cyberciti.biz/faq/linux-unix-script-check-if-file-empty-or-not/
  [ -s ../../../"$i" ] && bash -c "! ../../../scripts/docker-compose-config.bash -e .env ../../../$i 2>&1 | cat | grep \"must be unique\""
done

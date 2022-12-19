#!/bin/bash
#

set -o nounset
set -o pipefail
IFS=$'\n\t'

# For pre-commit hook
# via https://stackoverflow.com/questions/3349105/how-can-i-set-the-current-working-directory-to-the-directory-of-the-script-in-ba
cd "$(dirname "$0")" || exit 1

# via https://sharats.me/posts/shell-script-best-practices/?utm_source=pocket_mylist
#TRACE=1
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

if [ -f ".venv/bin/activate" ] ; then
	sleep 0
else
    echo "Installing and creating venv.."
    pip3 install virtualenv >/dev/null 2>&1
    virtualenv -p python3 .venv >/dev/null 2>&1
fi
set -o allexport
# shellcheck disable=1091,1090
source .venv/bin/activate
python -m pip install -r requirements.txt >/dev/null 2>&1

for i in "$@"; do
  # assert file not empty via https://www.cyberciti.biz/faq/linux-unix-script-check-if-file-empty-or-not/
  bash -c "[ -s ../../../$i ]" && python template.env.main.py ./../../../"$i"
  # Build and check assoc. .dotenv file
  export DOTENV_FILENAME='.env'
  DOTENV_PATH=$(dirname "$i")/$DOTENV_FILENAME
  export DOTENV_PATH
  # assert file not empty via https://www.cyberciti.biz/faq/linux-unix-script-check-if-file-empty-or-not/
  pushd ../../../"$(dirname "$i")" && make $DOTENV_FILENAME && popd || exit 1
  set -o allexport
  # shellcheck disable=1091,1090
  . "../../../$DOTENV_PATH"
  set +o allexport
  rm .env.example || true
  [ -f ../../../"$i" ] && sleep 0 || echo "FILE ../../../$i does not exist."
  ln -P ../../../"$i" .env.example
  python -c "from env_validate import validate_env; validate_env()" && python .env.main.py ../../../"$DOTENV_PATH"
done

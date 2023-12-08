#!/bin/bash
#
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o nounset
set -o pipefail
set -o errexit
IFS=$'\n\t'

# For pre-commit hook
# via https://stackoverflow.com/questions/3349105/how-can-i-set-the-current-working-directory-to-the-directory-of-the-script-in-ba


# via https://sharats.me/posts/shell-script-best-practices/?utm_source=pocket_mylist
TRACE=1
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi
cd "$(dirname "$0")"
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


#######
#
# Paths
this_script_dir=$(dirname "$0")
cd "$this_script_dir"
repo_basedir=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1091,SC1090
source "$repo_basedir"/scripts/portable.sh
# Source bash logging tools
# shellcheck disable=SC1091,SC1090
source "$repo_basedir"/scripts/logger.bash
#####################
repo_config=$(cat "$repo_basedir"/.config.location)
set -o allexport
# shellcheck disable=SC1090
export DOCKER_IMAGE_TAG=master-github-latest
# shellcheck source=/dev/null.
source "$repo_config"
set +o allexport
#####################
rm "$repo_basedir"/docker-compose.yml 2>/dev/null || true
rm "$repo_basedir"/.env-devel 2>/dev/null || true
# via https://stackoverflow.com/a/2466755
rm -rf osparc-simcore 2>/dev/null || true
git clone "${GIT_SIMCORE_REPO_URL}"
pushd osparc-simcore
# shellcheck disable=2001
tagregex=$(echo "$TAGS_SIMCORE_REPO" | sed -e "s/^tags: //")
if [ -z "$tagregex" ]; then
  latestMatchingTag=HEAD
elif [ "$tagregex" == \"\" ]; then
  latestMatchingTag=HEAD
else
  latestMatchingTag=$(git tag --list --sort=creatordate | grep -E "$tagregex" | tail -1 )
fi
echo Checking out "$latestMatchingTag" on osparc-simcore
git checkout "$latestMatchingTag" services/docker-compose.yml
git checkout "$latestMatchingTag" .env-devel
cp services/docker-compose.yml "$repo_basedir"
cp .env-devel "$repo_basedir"
popd
rm -rf osparc-simcore 2>/dev/null || true
"$repo_basedir"/scripts/deployments/startup_script.bash
# shellcheck disable=SC2143
if [[ -z $(grep '[^[:space:]]' "$repo_basedir"/stack.yml) ]] ; then
  error_exit "stack.yml is empty"
  exit 1
fi
"$repo_basedir"/scripts/docker-compose-config.bash -e .env "$repo_basedir"/stack.yml 2>&1 | cat
rm "$repo_basedir"/stack.yml 2>/dev/null || true
rm "$repo_basedir"/docker-compose.yml 2>/dev/null || true
rm "$repo_basedir"/.env-devel 2>/dev/null || true

#!/bin/bash
#
rm -rf osparc-simcore
git clone https://github.com/ITISFoundation/osparc-simcore.git
cd osparc-simcore/ || exit 1
cd packages/ || exit 1
cd pytest-simcore/ || exit 1
make devenv
# shellcheck disable=SC1091
. ../../.venv/bin/activate
make install-dev
pip install -r requirements/tests_base.txt
cd ../../../
pip install -r requirements.txt
python3 provision_database.py
rm -rf osparc-simcore
deactivate
###########################

# Purpose

This python scripts check if Graylog is running, and add the necessary inputs if the Graylos instance is a new one..
**Nota bene**:  Use content packs to preconfigure dashboards, ...

# Installation

* Capture env-vars from repo.config
```console
cd .. && make .env && cd scripts
```

* Create a virtualenvironment with python 3.X and activate it
```console
python3 -m venv venv
source venv/bin/activate
```
* Install the dependancies
```console
pip install -r requirements.txt
```

* Launch configuration
```console
python configure.py
```

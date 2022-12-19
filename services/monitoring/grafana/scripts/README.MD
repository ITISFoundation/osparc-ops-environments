# Purpose

This python scripts export and import all the folders/datasources/dashboards of a grafana instance and is used to handle the different configuration of all Osparc Grafana instances.
At each update on grafana dashboards and/or datasources, the export script has to be run, and the changes pushed to the git repo.

# Installation

* Create a virtualenvironment with python 3.X and activate it
```console
python3 -m venv venv
source venv/bin/activate
```
* Install the dependancies
```console
pip install -r requirements.txt
```

* To export everything (has to be run each time something is updated on Grafana)
```console
python export.py
```

* To import everything
```console
python import.py
```

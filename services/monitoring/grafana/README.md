# [grafana]


# How import/export works:

## Concepts:
Grafana dashboards will be lost if the docker volume associated to grafana is deleted.
Furthermore, we desire to have the same dashboards across all deployments in principle. Additionally, special deployments might have further custom dashboards.
For this reason, a sophisticated import/export python script, using the grafana REST Api is provided.

## Background:
Grafana instances are composed of dashboards and datasources. Datasources can be Prometheus, pgSQL, etc.
Dashboards should look & feel similar across all deployments, but datasources might differ.

### Using the export script:
Exported dashboards & datasources are exported into the gitignored `provisioning/exported` folder, according to the `MACHINE_FQDN` environment variable.

### Using the import script:
Dashboards and datasources are imported from `provisioning/allDeployments`, and data placed in `provisioning/${MACHINE_FQDN}` are added additionally.
In order to make different datasources, with potentially different names etc., work smoothly, a config-file named `datasources2dashboards.yaml` is provided in `provisioning/${MACHINE_FQDN}`. This file specifies default datasources for common datasource-types (Prometheus, pgSQL, etc.) per deployment. Additionally, custom dashboards and their individual used datasources may be specified there.

### Creating or changing a grafana dashboard and persisting it
1. Create / Change the dashboard in grafana
2. Save it in grafana
3. Run the export script
4. Copy the exported json of the dashboard to the `provisioning/allDeployments` folder (potentially overwrite the old version)
5. Run the import script, refresh your grafana-browser windows (clear the cache if possible) and validate it still works.
6. git commit the changes
7. Checkout the branches of the other deployments, cherry-pick the changes, go to step 5 for each deployment.


### How to run the import/export scripts
The scripts do not need to be run on the deployments' machines, but can be run locally

* Create a virtualenvironment with python 3.X and activate it
```console
python3 -m venv venv
source venv/bin/activate
```
* Install the dependncies
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

## Important pitfalls
- If a new docker volume for grafana is set up, an API key with name "reporter" and permission "read" needs to be set up to get the NIH metric working.
- Some gitlab CI tests might fail (NIH metrics) if the dashboard UID changes.


<!-- References below -->
[grafana]:https://grafana.com
[prometheus]:https://prometheus.io/

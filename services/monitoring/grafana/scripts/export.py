# pylint: skip-file
import json
import os
import shutil
import warnings
from pathlib import Path

import requests
import typer
from environs import Env

repo_config_location = os.getenv("REPO_CONFIG_LOCATION")
try:
    assert repo_config_location is not None
except Exception:
    print("ERROR: Env-Var REPO_CONFIG_LOCATION not set.")
    exit(1)
if "\n" in repo_config_location:
    repo_config_location = repo_config_location.split("\n")[0]

env = Env()
env.read_env(repo_config_location, recurse=False)

warnings.filterwarnings(
    "ignore",
    ".*Adding certificate verification is strongly advised.*",
)


def main(foldername: str = ""):
    # We delete the previous files
    if foldername == "":
        directory = "./../provisioning/exported/" + env.str("MACHINE_FQDN")

        export_dir = Path.cwd() / ".." / "provisioning/exported"
        export_dir.mkdir(parents=True, exist_ok=True)
    else:
        directory = foldername
    if os.path.exists(directory):
        shutil.rmtree(directory)

    os.mkdir(directory)

    # We export the Datasources
    print("**************** Export datasources *******************")
    os.mkdir(directory + "/datasources")
    url = "https://monitoring." + env.str("MACHINE_FQDN") + "/grafana/api/"
    session = requests.Session()
    session.auth = (env.str("SERVICES_USER"), env.str("SERVICES_PASSWORD"))
    hed = {"Content-Type": "application/json"}

    r = session.get(url + "datasources", headers=hed, verify=False)
    for datasource in r.json():
        rDatasource = session.get(
            url + "datasources/" + str(datasource["id"]), headers=hed, verify=False
        )
        with open(
            directory + "/datasources/" + str(datasource["id"]) + ".json", "w"
        ) as outfile:
            # If the datasource is Prometheus, we remove the login/password credentials
            jsonData = rDatasource.json()
            if jsonData["type"] == "prometheus":
                jsonData["basicAuthUser"] = ""
                jsonData["basicAuthPassword"] = ""
            json.dump(jsonData, outfile, sort_keys=True, indent=2)
            print("Export datasource " + jsonData["name"])

    # We export the dashboards
    print("**************** Export dashboards *******************")
    os.mkdir(directory + "/dashboards")
    r = session.get(url + "search?query=%", headers=hed, verify=False)
    for dashboard in r.json():
        rDashboard = session.get(
            url + "dashboards/uid/" + str(dashboard["uid"]), headers=hed, verify=False
        )
        if rDashboard.json()["meta"]["isFolder"] is not True:
            if (
                os.path.exists(
                    directory
                    + "/dashboards/"
                    + rDashboard.json()["meta"]["folderTitle"]
                )
                == False
            ):
                os.mkdir(
                    directory
                    + "/dashboards/"
                    + rDashboard.json()["meta"]["folderTitle"]
                )

            with open(
                directory
                + "/dashboards/"
                + rDashboard.json()["meta"]["folderTitle"]
                + "/"
                + str(rDashboard.json()["dashboard"]["title"])
                + ".json",
                "w",
            ) as outfile:
                print("Export Dashboard " + rDashboard.json()["dashboard"]["title"])
                exportedDashboard = rDashboard.json()
                exportedDashboard["meta"].pop("updated", None)
                exportedDashboard["meta"].pop("created", None)
                exportedDashboard["meta"].pop("folderId", None)
                exportedDashboard["meta"].pop("folderUid", None)
                exportedDashboard["meta"].pop("folderUrl", None)
                exportedDashboard["meta"].pop("version", None)
                exportedDashboard.pop("id", None)
                exportedDashboard["dashboard"].pop("id", None)
                exportedDashboard.pop("iteration", None)
                json.dump(exportedDashboard, outfile, sort_keys=True, indent=2)

    # Export Alerts
    print("**************** Export alerts  *******************")
    if os.path.exists(directory + "/alerts/") == False:
        os.mkdir(directory + "/alerts/")
    r = session.get(url + "ruler/grafana/api/v1/rules", headers=hed, verify=False)
    for alert in r.json()["ops"]:
        with open(directory + "/alerts/" + alert["name"] + ".json", "w") as outfile:
            print("Export Alert " + alert["name"])
            # Remove UID if present
            for ruleIter in range(len(alert["rules"])):
                alert["rules"][ruleIter]["grafana_alert"].pop("uid", None)
                # Remove orgId
                alert["rules"][ruleIter]["grafana_alert"].pop("orgId", None)
                # Remove id
                alert["rules"][ruleIter]["grafana_alert"].pop("id", None)
                # Remove id
                alert["rules"][ruleIter]["grafana_alert"].pop("namespace_id", None)
                # Remove id
                alert["rules"][ruleIter]["grafana_alert"].pop("namespace_uid", None)
                if (
                    str(env.str("MACHINE_FQDN") + " - ")
                    in alert["rules"][ruleIter]["grafana_alert"]["title"]
                ):
                    alert["rules"][ruleIter]["grafana_alert"]["title"] = alert["rules"][
                        ruleIter
                    ]["grafana_alert"]["title"].replace(
                        str(env.str("MACHINE_FQDN") + " - "), ""
                    )
            json.dump(alert, outfile, sort_keys=True, indent=2)


if __name__ == "__main__":
    """
    Imports grafana dashboard from dumped json files via the Grafana API

    If --foldername is used, the data is taken from this location.
    Otherwise, the default ops-repo folder is assumed.
    """
    typer.run(main)

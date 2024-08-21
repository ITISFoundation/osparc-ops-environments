# pylint: disable=pointless-string-statement,too-many-statements
import json
import os
import shutil
import sys
import warnings
from pathlib import Path

import requests
import typer
from environs import Env

repo_config_location = os.getenv("REPO_CONFIG_LOCATION")
if not repo_config_location:
    print("ERROR: Env-Var REPO_CONFIG_LOCATION not set.")
    sys.exit(1)
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
        r_datasource = session.get(
            url + "datasources/" + str(datasource["id"]), headers=hed, verify=False
        )
        with open(
            directory + "/datasources/" + str(datasource["id"]) + ".json", "w"
        ) as outfile:
            # If the datasource is Prometheus, we remove the login/password credentials
            json_data = r_datasource.json()
            if json_data["type"] == "prometheus":
                json_data["basicAuthUser"] = ""
                json_data["basicAuthPassword"] = ""
            json.dump(json_data, outfile, sort_keys=True, indent=2)
            print("Export datasource " + json_data["name"])

    # We export the dashboards
    print("**************** Export dashboards *******************")
    os.mkdir(directory + "/dashboards")
    r = session.get(url + "search?query=%", headers=hed, verify=False)
    for dashboard in r.json():
        r_dashboard = session.get(
            url + "dashboards/uid/" + str(dashboard["uid"]), headers=hed, verify=False
        )
        if r_dashboard.json()["meta"]["isFolder"] is not True:
            if (
                os.path.exists(
                    directory
                    + "/dashboards/"
                    + r_dashboard.json()["meta"]["folderTitle"]
                )
                == False
            ):
                os.mkdir(
                    directory
                    + "/dashboards/"
                    + r_dashboard.json()["meta"]["folderTitle"]
                )

            with open(
                directory
                + "/dashboards/"
                + r_dashboard.json()["meta"]["folderTitle"]
                + "/"
                + str(r_dashboard.json()["dashboard"]["title"])
                + ".json",
                "w",
            ) as outfile:
                print("Export Dashboard " + r_dashboard.json()["dashboard"]["title"])
                exported_dashboard = r_dashboard.json()
                exported_dashboard["meta"].pop("updated", None)
                exported_dashboard["meta"].pop("created", None)
                exported_dashboard["meta"].pop("folderId", None)
                exported_dashboard["meta"].pop("folderUid", None)
                exported_dashboard["meta"].pop("folderUrl", None)
                exported_dashboard["meta"].pop("version", None)
                exported_dashboard.pop("id", None)
                exported_dashboard["dashboard"].pop("id", None)
                exported_dashboard.pop("iteration", None)
                json.dump(exported_dashboard, outfile, sort_keys=True, indent=2)

    # Export Alerts
    print("**************** Export alerts  *******************")
    if not os.path.exists(directory + "/alerts/"):
        os.mkdir(directory + "/alerts/")
    r = session.get(url + "ruler/grafana/api/v1/rules", headers=hed, verify=False)
    for alert in r.json()["ops"]:
        with open(directory + "/alerts/" + alert["name"] + ".json", "w") as outfile:
            print("Export Alert " + alert["name"])
            # Remove UID if present
            for rule_iter in range(len(alert["rules"])):
                alert["rules"][rule_iter]["grafana_alert"].pop("uid", None)
                # Remove orgId
                alert["rules"][rule_iter]["grafana_alert"].pop("orgId", None)
                # Remove id
                alert["rules"][rule_iter]["grafana_alert"].pop("id", None)
                # Remove id
                alert["rules"][rule_iter]["grafana_alert"].pop("namespace_id", None)
                # Remove id
                alert["rules"][rule_iter]["grafana_alert"].pop("namespace_uid", None)
                if (
                    str(env.str("MACHINE_FQDN") + " - ")
                    in alert["rules"][rule_iter]["grafana_alert"]["title"]
                ):
                    alert["rules"][rule_iter]["grafana_alert"]["title"] = alert[
                        "rules"
                    ][rule_iter]["grafana_alert"]["title"].replace(
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

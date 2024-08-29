# pylint: disable=invalid-name,pointless-string-statement,too-many-statements,too-many-branches
import glob
import json
import os
import sys
import time
import warnings
from pathlib import Path

import requests
import typer
import yaml
from environs import Env

warnings.filterwarnings(
    "ignore",
    ".*Adding certificate verification is strongly advised.*",
)

repo_config_location = os.getenv("REPO_CONFIG_LOCATION")
assert repo_config_location is not None
if "\n" in repo_config_location:
    repo_config_location = repo_config_location.split("\n")[0]

env = Env()
env.read_env(repo_config_location, recurse=False)


def dictionary_traversal_datasource_uid_replacement(
    _input, datasourceType, replacementID
):
    """
    Traverses Dictionary, potentially with lists of dicts, recursively.
    If a "datasource" dict tis found, the uid value is replaced.
    """
    for key, value in _input.items():
        # If we found the target dict "datasource"
        if (
            key == "datasource"
            and "uid" in value
            and "type" in value
            and isinstance(value, dict)
        ):
            if value["type"] == datasourceType:
                value["uid"] = replacementID
        # Recursively step down if value is a dict
        elif isinstance(value, dict):
            # if "datasource" in value:
            #    print("v: ",value)
            dictionary_traversal_datasource_uid_replacement(
                value, datasourceType, replacementID
            )
        # Iterate list of dict
        elif isinstance(value, list) and len(value) > 0 and isinstance(value[0], dict):
            for i in value:
                dictionary_traversal_datasource_uid_replacement(
                    i, datasourceType, replacementID
                )
        # Ignore endpoints of recursive traversal
        else:
            time.sleep(0)  # Do nothing


def subsituteDatasources(
    directoriesDatasources,
    configFilePath,
    dashboardTitle,
    jsonObject,
):
    if configFilePath.is_file():
        with open(str(configFilePath)) as cfile:
            configYaml = yaml.load(cfile, Loader=yaml.FullLoader)
    else:
        print("ERROR: Config file missing at: " + str(configFilePath))
        sys.exit(1)
    ######
    ######
    listOfDatasources = []
    for file in directoriesDatasources:
        with open(file) as jsonFile:
            jsonObjectDatasource = json.load(jsonFile)
            objectToKeepTrack = {
                "name": jsonObjectDatasource["name"],
                "uid": jsonObjectDatasource["uid"],
                "type": jsonObjectDatasource["type"],
            }
            listOfDatasources.append(objectToKeepTrack)

    listOfDatasourcesWhichAreUnique = [
        i
        for i in listOfDatasources
        if [j["type"] for j in listOfDatasources].count(i["type"]) == 1
    ]
    listOfDatasourcesWhichAreNotUnique = [
        i
        for i in listOfDatasources
        if [j["type"] for j in listOfDatasources].count(i["type"]) > 1
    ]
    #
    #######
    #
    for presentDatasource in listOfDatasourcesWhichAreUnique:
        # print("DEBUG: Subsituting unqiue type ",presentDatasource["type"])
        dictionary_traversal_datasource_uid_replacement(
            jsonObject, presentDatasource["type"], presentDatasource["uid"]
        )
    for nonUniqueDatasource in listOfDatasourcesWhichAreNotUnique:
        assert nonUniqueDatasource["type"] in {
            i["type"] for i in configYaml["defaults"]
        }
        defaultNameForCurrent = [
            i["datasource_name"]
            for i in configYaml["defaults"]
            if i["type"] == nonUniqueDatasource["type"]
        ][0]
        if nonUniqueDatasource["name"] == defaultNameForCurrent:
            # print("DEBUG: Subsituting non-unqiue type ",nonUniqueDatasource["type"], " as given in defaults.")
            dictionary_traversal_datasource_uid_replacement(
                jsonObject, nonUniqueDatasource["type"], nonUniqueDatasource["uid"]
            )
    # Subsitute custom dashboard mappings now
    if "datasources2dashboards" in configYaml:
        if len(configYaml["datasources2dashboards"]) > 0:
            if dashboardTitle in [
                i["dashboard_name"] for i in configYaml["datasources2dashboards"]
            ]:
                currentConfigMapping = [
                    i
                    for i in configYaml["datasources2dashboards"]
                    if i["dashboard_name"] == dashboardTitle
                ][0]["mapping"]
                for j in currentConfigMapping.copy():
                    j["uid"] = [
                        i["uid"]
                        for i in listOfDatasources
                        if i["name"] == j["datasource_name"]
                    ][0]
                    # print("DEBUG: Subsituting custom type ",j["type"], " as given in config.")
                    dictionary_traversal_datasource_uid_replacement(
                        jsonObject, j["type"], j["uid"]
                    )


def main(foldername: str = "", overwrite: bool = True):
    # Get mail adress for alerts:
    grafanaAlertingMailTarget = env.str("GRAFANA_ALERTS_MAIL", default=None)
    grafanaAlertingSlackTarget = env.str("GRAFANA_ALERTS_SLACK", default=None)

    # We first import the datasources
    url = "https://monitoring." + env.str("MACHINE_FQDN") + "/grafana/api/"
    #
    #
    print("**************** GRAFANA PROVISIONING *******************")
    print("Assuming deployment", env.str("MACHINE_FQDN"), "at", url)
    if grafanaAlertingMailTarget:
        print("Assuming alerting mail address", grafanaAlertingMailTarget)
    if grafanaAlertingSlackTarget:
        print("Assuming alerting slack webhook", grafanaAlertingSlackTarget)
    #
    #
    session = requests.Session()
    session.auth = (env.str("SERVICES_USER"), env.str("SERVICES_PASSWORD"))
    hed = {"Content-Type": "application/json"}

    if foldername == "":
        directoriesDatasources = glob.glob("./../assets/datasources/*")
        directoriesDatasources += glob.glob("./../assets/shared" + "/datasources/*")
    else:
        directoriesDatasources = glob.glob(foldername + "/datasources/*")
    #
    print("**************** Add datasources *******************")
    if overwrite:
        # Get all datasources
        # print("Deleting datasource " + str(i["uid"]) + " - " + str(i["name"]))
        r = session.get(url + "datasources", headers=hed, verify=False)
        if r.status_code > 300:
            print("Recieved non-200 status code upon import: ", str(r.status_code))
            print("ABORTING!")
            print(r.json())
            sys.exit(1)
        for i in r.json():
            print("Response: ", r.status_code)
            r = session.delete(
                url + "datasources/uid/" + str(i["uid"]), headers=hed, verify=False
            )
    listOfDatasources = []
    for file in directoriesDatasources:
        with open(file) as jsonFile:
            jsonObjectDatasource = json.load(jsonFile)
            jsonFile.close()

        # We add the credentials for the PGSQL Databases with the secureJsonData field
        # DK Mar2023 : THIS IS CURRENTLY NOT USED
        if jsonObjectDatasource["type"].lower() == "postgres":
            print("postgres datasource is currently not supported (deprecated)")
            sys.exit(1)
        elif jsonObjectDatasource["type"] == "Prometheus":
            jsonObjectDatasource["basicAuthUser"] = env.str("SERVICES_USER")
            jsonObjectDatasource["basicAuthPassword"] = env.str("SERVICES_PASSWORD")
            jsonObjectDatasource["url"] = "http://prometheus:" + env.str(
                "MONITORING_PROMETHEUS_PORT"
            )
        r = session.post(
            url + "datasources", json=jsonObjectDatasource, headers=hed, verify=False
        )
        objectToKeepTrack = {
            "name": jsonObjectDatasource["name"],
            "uid": jsonObjectDatasource["uid"],
            "type": jsonObjectDatasource["type"],
        }
        listOfDatasources.append(objectToKeepTrack)
        # print(r.json())
        print("Import of datasource " + jsonObjectDatasource["name"])
        if r.status_code != 200:
            print("Received non-200 status code upon import: ", str(r.status_code))
            print("JSON file failed uploading.")
        #
    # Second, we import the folders structure
    directoriesData = []
    if foldername == "":
        directoriesDashboards = glob.glob("./../assets/dashboards/*")
        directoriesDashboards = [
            *directoriesDashboards,
            *list(glob.glob("./../assets/shared" + "/dashboards/*")),
        ]
    else:
        directoriesDashboards = glob.glob(foldername + "/dashboards/*")
    for directory in directoriesDashboards:
        if ".json" in directory:
            print(
                "Error: Looking for folders but got json file. Is your folder structure organized properly?\nABORTING"
            )
            sys.exit(1)
        for file in glob.glob(directory + "/*"):
            with open(file) as jsonFile:
                jsonObject = json.load(
                    jsonFile
                )  # Assert the file is valid json, otherwise will give an error
                break
        directoriesData.append(os.path.basename(os.path.normpath(directory)))
    directoriesData = list(set(directoriesData))

    print("Deleting alerts")
    r = session.get(url + "v1/provisioning/alert-rules", headers=hed, verify=False)
    # Status code is 404 if no alerts are present. Handling it:
    if r.status_code != 404:
        for alert in r.json():
            deleteResponse = session.delete(
                url + f"v1/provisioning/alert-rules/{alert['uid']}",
                headers=hed,
                verify=False,
            )
            if deleteResponse.status_code < 200 or deleteResponse.status_code > 204:
                print(
                    "Received status code not 200-204 upon delete: ",
                    str(deleteResponse.status_code),
                )
                print("ABORTING!")
                sys.exit(1)

    # We add them in grafana
    print("**************** Add folders *******************")
    if overwrite:
        print("Deleting all folders and dashboards")
        # Get all datasources
        r = session.get(url + "folders", headers=hed, verify=False)
        for i in r.json():
            r = session.delete(
                url + "folders/" + str(i["uid"]), headers=hed, verify=False
            )
    print("Adding folders")
    for directoryData in directoriesData:
        r = session.post(
            url + "folders", json={"title": directoryData}, headers=hed, verify=False
        )
        if r.status_code != 200:
            print("Received non-200 status code upon import: ", str(r.status_code))
            print("JSON file failed uploading:")
            print(json.dumps(directoryData, sort_keys=True, indent=2))
    print("**************** Add dashboards *******************")
    #
    #
    configFilePath = Path("./../assets/datasources2dashboards.yaml")

    # Finally we import the dashboards
    for directory in directoriesDashboards:
        for file in glob.glob(directory + "/*.json"):
            with open(file) as jsonFile:
                jsonObject = json.load(jsonFile)
                # We set the folder ID
                r = session.get(url + "folders", headers=hed, verify=False)
                folderID = None
                for i in r.json():
                    if i["title"] == file.split("/")[-2]:
                        folderID = i["id"]
                        break
                assert folderID
                print("Add dashboard " + jsonObject["dashboard"]["title"])
                # Subsitute datasource UID
                # pylint: disable=too-many-function-args
                subsituteDatasources(
                    directoriesDatasources,
                    configFilePath,
                    jsonObject["dashboard"]["title"],
                    jsonObject,
                )
                dashboard = {"Dashboard": jsonObject["dashboard"]}
                # DEBUGPRINT
                # with open(".out.temp","w") as ofile:
                #    ofile.write(json.dumps(jsonObject,indent=2))

                dashboard["Dashboard"]["id"] = "null"
                dashboard["overwrite"] = True
                dashboard["folderId"] = folderID
                r = session.post(
                    url + "dashboards/db", json=dashboard, headers=hed, verify=False
                )

                if r.status_code != 200:
                    print(
                        "Received non-200 status code upon import: ", str(r.status_code)
                    )
                    # print(r.json())
                    print("JSON file failed uploading.")
                    sys.exit()

    # IMPORT ALERTS
    # 1. Provision Alerting User
    print("**************** Add Target Mail Bucket / Slack Webhook *******************")
    if grafanaAlertingMailTarget:
        mailAddressProvisioningJSON = (
            '''{
        	"template_files": {},
        	"alertmanager_config": {
        		"route": {
        			"receiver": "'''
            + grafanaAlertingMailTarget.split("@")[0]
            + '''",
        			"continue": false,
        			"group_by": [],
        			"routes": []
        		},
        		"templates": null,
        		"receivers": [{
        			"name": "'''
            + grafanaAlertingMailTarget.split("@")[0]
            + '''",
        			"grafana_managed_receiver_configs": [{
        				"name": "'''
            + grafanaAlertingMailTarget.split("@")[0]
            + '''",
        				"type": "email",
        				"disableResolveMessage": false,
        				"settings": {
        					"addresses": "'''
            + grafanaAlertingMailTarget
            + """"
        				},
        				"secureFields": {}
        			}]
        		}]
        	}
        }"""
        )
    else:
        slackWebhookProvisioningJSON = (
            '''{
        	"template_files": {},
        	"alertmanager_config": {
        		"route": {
        			"receiver": "'''
            + "slackwebhook"
            + '''",
        			"continue": false,
        			"group_by": [],
        			"routes": []
        		},
        		"templates": null,
        		"receivers": [{
        			"name": "'''
            + "slackwebhook"
            + '''",
        			"grafana_managed_receiver_configs": [{
        				"name": "'''
            + "slackwebhook"
            + '''",
        				"type": "slack",
        				"disableResolveMessage": false,
        				"settings": {
        					"username": "'''
            + "grafana-alert"
            + '''"
        				},
        				"secureSettings":
                        {
                            "url": "'''
            + str(grafanaAlertingSlackTarget)
            + """",
                            "token": ""
                        }
        			}]
        		}]
        	}
        }"""
        )
    r = session.post(
        url + "alertmanager/grafana/config/api/v1/alerts",
        json=json.loads(
            mailAddressProvisioningJSON
            if grafanaAlertingMailTarget
            else slackWebhookProvisioningJSON
        ),
        verify=False,
        headers=hed,
    )
    if r.status_code != 202:
        print(
            "Received non-202 status code upon mail address provisioning: ",
            str(r.status_code),
        )
        print(
            "POST to URL", url + "alertmanager/grafana/config/api/v1/alerts", "failed"
        )
        print("JSON file failed uploading:")
        print(
            mailAddressProvisioningJSON
            if grafanaAlertingMailTarget
            else slackWebhookProvisioningJSON
        )
        print("Response Error:")
        print(r.json())
        sys.exit(1)
    # 2. Import alerts
    print("**************** Add alerts *******************")
    # Finally we import the dashboards
    if foldername == "":
        directoriesAlerts = glob.glob("./../assets/alerts/*")
        directoriesAlerts += glob.glob("./../assets/shared" + "/alerts/*")
    else:
        directoriesAlerts = glob.glob(foldername + "/alerts/*")
    #
    print("***************** Add folders ******************")
    r = session.get(
        url + "folders",
        headers=hed,
        verify=False,
    )
    ops_uid = (
        r.json()[
            next((i for i, item in enumerate(r.json()) if item["title"] == "ops"), None)
        ]["uid"]
        if next((i for i, item in enumerate(r.json()) if item["title"] == "ops"), None)
        else None
    )
    if not ops_uid:
        print("Could not find required grafana folder named `ops`. Aborting.")
        sys.exit(1)
    print(f"Info: Adding alerts always to folder `ops`, determined with uid {ops_uid}.")
    if r.status_code != 200:
        print(
            "Received non-200 status code upon alerts folder creation: ",
            str(r.status_code),
        )
        sys.exit(1)
    #
    for file in directoriesAlerts:
        with open(file) as jsonFile:
            jsonObject = json.load(jsonFile)
            # pylint: disable=too-many-nested-blocks
            for rule in jsonObject["rules"]:
                # Add deployment name to alert name
                rule["grafana_alert"]["title"] = (
                    env.str("MACHINE_FQDN") + " - " + rule["grafana_alert"]["title"]
                )
                # Subsitute UIDs of datasources
                # pylint: disable=too-many-function-args
                subsituteDatasources(
                    directoriesDatasources,
                    configFilePath,
                    jsonObject["name"],
                    rule,
                )
                # Propagate subsituted UIDs to other fields
                for i in rule["grafana_alert"]["data"]:
                    if "datasourceUid" in i:
                        if "model" in i:
                            if "datasource" in i["model"]:
                                if "type" in i["model"]["datasource"]:
                                    if (
                                        i["model"]["datasource"]["type"]
                                        != "grafana-expression"
                                    ):
                                        i["datasourceUid"] = i["model"]["datasource"][
                                            "uid"
                                        ]
                # Remove UID if present
                rule["grafana_alert"].pop("uid", None)

            print("Add alerts " + jsonObject["name"])

            r = session.post(
                url + f"ruler/grafana/api/v1/rules/{ops_uid}",
                json=jsonObject,
                headers=hed,
                verify=False,
            )
            if r.status_code != 202:
                print("Received non-202 status code upon import: ", str(r.status_code))
                print(r.json())
                print("JSON file failed uploading.")
                sys.exit()


if __name__ == "__main__":
    """
    Imports grafana dashboard from dumped json files via the Grafana API

    If --foldername is used, the data is taken from this location.
    Otherwise, the default ops-repo folder is assumed.
    """
    typer.run(main)

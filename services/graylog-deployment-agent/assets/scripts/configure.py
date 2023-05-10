import copy
import json
import random
import uuid
import warnings
from time import sleep

import requests
import yaml
from environs import Env, EnvError
from tenacity import retry, stop_after_attempt, wait_random
from yaml.loader import SafeLoader

warnings.filterwarnings(
    "ignore",
    ".*Adding certificate verification is strongly advised.*",
)

env = Env()
env.read_env("./../.env", recurse=False)


def log_attempt_number(retry_state):
    """return the result of the last call attempt"""
    print(f"Retrying: {retry_state.attempt_number}...")


@retry(
    stop=stop_after_attempt(10),
    wait=wait_random(min=1, max=10),
    after=log_attempt_number,
)
def checkGraylogOnline():
    url = "https://monitoring." + env.str("MACHINE_FQDN") + "/graylog/api/users"
    hed = {"Content-Type": "application/json", "Accept": "application/json"}
    session = requests.Session()
    session.auth = (
        "admin",
        env.str("SERVICES_PASSWORD"),
    )
    r = session.get(url, headers=hed, verify=False)
    if r.status_code != 401 and str(r.status_code) != "200":
        print(r.status_code)
        sleep(15)
        raise Exception
    else:
        return True


@retry(stop=stop_after_attempt(5), wait=wait_random(min=1, max=10))
def getGraylogInputs(session, headers, url):
    # We check if graylog has inputs, if not we add a new one
    r = session.get(url, headers=headers, verify=False)
    # DEBUG
    if r.status_code == 200:
        print("Successfully send GET /api/system/inputs")
        print("Graylog is online :)")
        return r
    else:
        print(
            "Error while sending GET /api/system/inputs. Status code of the request : "
            + str(r.status_code)
            + " "
            + r.text
        )
        raise Exception


if __name__ == "__main__":
    print(
        "Waiting for graylog to run for provisioning. This can take up to some minutes, please be patient..."
    )
    try:
        checkGraylogOnline()
    except Exception as e:
        print(e)
        print("Exception or: Graylog is still not online.")
        print("Graylog script will now stop.")
        exit(1)

    session = requests.Session()
    session.auth = (
        "admin",
        env.str("SERVICES_PASSWORD"),
    )  # Graylog username is always "admin"
    hed = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Requested-By": "cli",
    }
    url = "https://monitoring." + env.str("MACHINE_FQDN") + "/graylog/api/system/inputs"
    r = getGraylogInputs(session, hed, url)
    if int(r.json()["total"]) == 0:
        print("No input found.")
        json_data = {
            "title": "standard GELF UDP input",
            "type": "org.graylog2.inputs.gelf.udp.GELFUDPInput",
            "global": "true",
            "configuration": {"bind_address": "0.0.0.0", "port": 12201},
        }
        json_dump = json.dumps(json_data)
        r = session.post(url, headers=hed, data=json_dump, verify=False)
        if r.status_code == 201:
            print("Input added with success !")
        else:
            print(
                "Error while adding the input. Status code of the request : "
                + str(r.status_code)
                + " "
                + r.text
            )
            print(r.json())
    else:
        print(str(r.json()["total"]) + " input(s) have been found.")

    #
    # Configure sending email notifications
    if env.str("GRAYLOG_ALERT_MAIL_ADDRESS") != "":
        url = (
            "https://monitoring."
            + env.str("MACHINE_FQDN")
            + "/graylog/api/events/notifications"
        )
        r = session.get(url, headers=hed, verify=False)
        if (
            len(
                [
                    noti
                    for noti in r.json()["notifications"]
                    if noti["title"]
                    == "Graylog " + env.str("MACHINE_FQDN") + " mail notification"
                ]
            )
            == 0
        ):
            raw_data = (
                '{"title":"Graylog '
                + env.str("MACHINE_FQDN")
                + ' mail notification","description":"","config":{"sender":"","subject":"Graylog event notification: ${event_definition_title}","user_recipients":[],"email_recipients":["'
                + env.str("GRAYLOG_ALERT_MAIL_ADDRESS")
                + '"],"type":"email-notification-v1"}}'
            )
            r = session.post(url, headers=hed, data=raw_data, verify=False)
            if r.status_code == 200:
                print("Mail Notification added with success !")
            else:
                print(
                    "Error while adding the Mail Notification. Status code of the request : "
                    + str(r.status_code)
                    + " "
                    + r.text
                )
                exit(1)
        else:
            print("Graylog Mail Notification already present - skipping...")
        # Keeping notification ID
        r = session.get(url, headers=hed, verify=False)
        mailNotificationID = [
            noti
            for noti in r.json()["notifications"]
            if noti["title"]
            == "Graylog " + env.str("MACHINE_FQDN") + " mail notification"
        ][0]["id"]

    #
    # Configure sending Slack notifications
    if env.str("GRAYLOG_SLACK_WEBHOOK_URL") != "":
        url = (
            "https://monitoring."
            + env.str("MACHINE_FQDN")
            + "/graylog/api/events/notifications"
        )
        r = session.get(url, headers=hed, verify=False)
        if (
            len(
                [
                    noti
                    for noti in r.json()["notifications"]
                    if noti["title"]
                    == "Graylog " + env.str("MACHINE_FQDN") + " Slack notification"
                ]
            )
            == 0
        ):
            raw_data = (
                '{"title":"Graylog '
                + env.str("MACHINE_FQDN")
                + """ Slack notification","description":"Slack notification","config": {
	    	    "color": "#FF0000",
	    	    "webhook_url": \""""
                + env.str("GRAYLOG_SLACK_WEBHOOK_URL")
                + """\",
	    	    "channel": "#"""
                + env.str("GRAYLOG_SLACK_WEBHOOK_CHANNEL")
                + """\",
                "custom_message":"--- [Event Definition] ---------------------------\\nTitle:       ${event_definition_title}\\nType:        ${event_definition_type}\\n--- [Event] --------------------------------------\\nTimestamp:            ${event.timestamp}\\nMessage:              ${event.message}\\nSource:               ${event.source}\\nKey:                  ${event.key}\\nPriority:             ${event.priority}\\nAlert:                ${event.alert}\\nTimestamp Processing: ${event.timestamp}\\nTimerange Start:      ${event.timerange_start}\\nTimerange End:        ${event.timerange_end}\\nEvent Fields:\\n${foreach event.fields field}\\n${field.key}: ${field.value}\\n${end}\\n${if backlog}\\n--- [Backlog] ------------------------------------\\nLast messages accounting for this alert:\\n${foreach backlog message}\\n"""
                + "https://monitoring."
                + env.str("MACHINE_FQDN")
                + "/graylog/messages"
                + """/${message.index}/${message.id}\\n${end}${end}\\n",
	    	    "user_name": "Graylog",
	    	    "notify_channel": true,
	    	    "link_names": false,
	    	    "icon_url": \""""
                + env.str("GRAYLOG_SLACK_WEBHOOK_ICON_URL")
                + """\",
	    	    "icon_emoji": "",
	    	    "backlog_size": 5,
	    	    "type": "slack-notification-v1"}}"""
            )
            r = session.post(
                url, headers=hed, verify=False, data=raw_data.encode("utf-8")
            )
            if r.status_code == 200:
                print("Slack Notification added with success !")
            else:
                print(
                    "Error while adding the Slack Notification. Status code of the request : "
                    + str(r.status_code)
                    + " "
                    + r.text
                )
                exit(1)
        else:
            print("Graylog Slack Notification already present - skipping...")
        # Keeping notification ID
        r = session.get(url, headers=hed, verify=False)
        slackNotificationID = [
            noti
            for noti in r.json()["notifications"]
            if noti["title"]
            == "Graylog " + env.str("MACHINE_FQDN") + " Slack notification"
        ][0]["id"]

    #
    # Configure log retention time
    try:
        url = (
            "https://monitoring."
            + env.str("MACHINE_FQDN")
            + "/graylog/api/system/indices/index_sets"
        )
        r = session.get(url, headers=hed, verify=False)
        indexOfInterest = [
            index
            for index in r.json()["index_sets"]
            if index["title"] == "Default index set"
        ][0]
        indexOfInterest[
            "rotation_strategy_class"
        ] = "org.graylog2.indexer.rotation.strategies.TimeBasedRotationStrategy"
        # Rotate logs every day
        indexOfInterest["rotation_strategy"] = {
            "rotation_period": "P1D",
            "type": "org.graylog2.indexer.rotation.strategies.TimeBasedRotationStrategyConfig",
        }
        indexOfInterest["retention_strategy"] = {
            "max_number_of_indices": str(env.str("GRAYLOG_RETENTION_TIME_DAYS")),
            "type": "org.graylog2.indexer.retention.strategies.DeletionRetentionStrategyConfig",
        }
        url = (
            "https://monitoring."
            + env.str("MACHINE_FQDN")
            + "/graylog/api/system/indices/index_sets"
        )
        raw_data = json.dumps(indexOfInterest)
        r = session.put(
            url + "/" + str(indexOfInterest["id"]),
            headers=hed,
            data=raw_data,
            verify=False,
        )
        if r.status_code == 200:
            print("Log retention time successfully updated !")
        else:
            print(
                "Error updating log retention time! Status code of the request : "
                + str(r.status_code)
                + " "
                + r.text
            )
    except EnvError as e:
        print(
            "Setting retention time: GRAYLOG_RETENTION_TIME_DAYS not set or failed, default retention is used..."
        )

    try:
        url = (
            "https://monitoring."
            + env.str("MACHINE_FQDN")
            + "/graylog/api/system/cluster/nodes"
        )
        r = session.get(url, headers=hed, verify=False).json()
        assert len(r["nodes"]) == 1
        node_uuid = r["nodes"][0]["node_id"]
        #
        url = (
            "https://monitoring."
            + env.str("MACHINE_FQDN")
            + "/graylog/api/system/inputs"
        )
        r2 = session.get(url, headers=hed, verify=False).json()
        if len([i for i in r2["inputs"] if i["title"] == "Syslog"]) == 0:
            raw_data = (
                '{"title":"Syslog","type":"org.graylog2.inputs.syslog.udp.SyslogUDPInput","configuration":{"bind_address":"0.0.0.0","port":'
                + env.str("GRAYLOG_SYSLOG_CAPTURE_PORT")
                + ',"recv_buffer_size":262144,"number_worker_threads":8,"override_source":null,"force_rdns":false,"allow_override_date":true,"store_full_message":true,"expand_structured_data":false},"global":true,"node":"'
                + node_uuid
                + '"}'
            )
            input_id = session.post(
                url, headers=hed, data=raw_data, verify=False
            ).json()["id"]
            #
            sleep(0.3)
            url = (
                "https://monitoring."
                + env.str("MACHINE_FQDN")
                + "/graylog/api/system/inputs/"
                + input_id
                + "/extractors"
            )
            raw_data = '{"title":"Fill container_name","cut_or_copy":"copy","source_field":"application_name","target_field":"container_name","extractor_type":"regex_replace","extractor_config":{"regex":"(^.)","replacement":"Syslog: $1"},"converters":{},"condition_type":"none","condition_value":""}'
            r3 = session.post(url, headers=hed, data=raw_data, verify=False)
            print("Graylog Syslog Capture setup successful")
        else:
            print("Graylog Syslog Capture already present, skipping...")
    except EnvError as e:
        print("Error setting up graylog syslog capturing.")

    # Configure Alerts
    print("Configuring Graylog Alerts...")
    with open("alerts.yaml") as f:
        data = yaml.load(f, Loader=SafeLoader)
        url = "https://monitoring." + env.str("MACHINE_FQDN") + "/graylog/api/streams"
        r = session.get(url, headers=hed, verify=False)
        if r.status_code == 200:
            streamsList = r.json()["streams"]
            streamAllEvents = [
                i
                for i in streamsList
                if "Stream containing all messages" in i["description"]
                or "default stream" == i["title"].lower()
            ]
            streamIDForAllMessages = streamAllEvents[0]["id"]
        else:
            print(
                "Could not determine ID of stream containing all events. Is graylog misconfigured? Exiting with error!"
            )
            exit(1)
        url = (
            "https://monitoring."
            + env.str("MACHINE_FQDN")
            + "/graylog/api/events/definitions"
        )
        r = session.get(url, headers=hed, params={"per_page": 2500}, verify=False)
        if r.status_code == 200:
            alreadyPresentAlerts = r.json()["event_definitions"]
            for presentAlert in alreadyPresentAlerts:
                resp = session.delete(
                    url + "/" + str(presentAlert["id"]), headers=hed, verify=False
                )
                if resp.status_code == 204:
                    print("Alert successfully deleted: " + str(presentAlert["title"]))
                else:
                    print(
                        "Could not delete alert. Failure: "
                        + str(resp.status_code)
                        + "!"
                    )
                    print(resp.json())
                    exit(1)
        for i in data:
            i["notifications"] = []
            if env.str("GRAYLOG_ALERT_MAIL_ADDRESS"):
                i["notifications"] += [{"notification_id": str(mailNotificationID)}]
            if env.str("GRAYLOG_SLACK_WEBHOOK_URL") != "":
                i["notifications"] += [{"notification_id": str(slackNotificationID)}]
            i["config"]["streams"] = [str(streamIDForAllMessages)]
            url = (
                "https://monitoring."
                + env.str("MACHINE_FQDN")
                + "/graylog/api/events/definitions?schedule=true"
            )
            resp = session.post(url, headers=hed, json=i, verify=False)
            if resp.status_code == 200:
                print("Alert successfully added: " + str(i["title"]))
            else:
                print("Could not add alert. Failure:", resp.status_code)
                print(resp.json())
                exit(1)
    # Configure Dashboards
    print("Configuring Graylog Dashbaords...")
    with open("dashboards.yaml") as f:
        data = yaml.load(f, Loader=SafeLoader)
        url = (
            "https://monitoring."
            + env.str("MACHINE_FQDN")
            + "/graylog/api/dashboards?query=&page=1&per_page=10&sort=title&order=asc"
        )
        r = session.get(url, headers=hed)
        if r.status_code == 200:
            totalDashboards = r.json()["total"]
            totalDashboards = int(totalDashboards)
            alreadyPresentDashboards = r.json()["views"]
            url = "https://monitoring." + env.str("MACHINE_FQDN") + "/graylog/api/views"
            for presentDashboard in alreadyPresentDashboards:
                resp = session.delete(
                    url + "/" + str(presentDashboard["id"]), headers=hed, verify=False
                )
                if resp.status_code == 200:
                    print(
                        "Dashboard successfully deleted: "
                        + str(presentDashboard["title"])
                    )
                else:
                    print(
                        "Could not delete a Dashboard. Failure: "
                        + str(resp.status_code)
                        + "!"
                    )
                    print(resp.json())
                    exit(1)
        else:
            print(
                "Could not fetch dashboards. Is graylog misconfigured? Exiting with error!"
            )
            exit(1)

        for i in data:
            url = (
                "https://monitoring."
                + env.str("MACHINE_FQDN")
                + "/graylog/api/views/search"
            )
            randSearchid = "".join(random.choice("0123456789abcdef") for n in range(24))
            randUuid = str(uuid.uuid4())
            print(randSearchid, randUuid)
            content = {
                "id": randSearchid,
                "queries": [
                    {
                        "id": randUuid,
                        "query": {"type": "elasticsearch", "query_string": ""},
                        "timerange": {"type": "relative", "from": 300},
                        "search_types": [],
                    }
                ],
                "parameters": [],
            }
            resp = session.post(url, headers=hed, json=content)
            if resp.status_code == 201:
                print("Search successfully added. ")
            else:
                print("Could not add search. Failure:", resp.status_code)
                print(resp.json())
                exit(1)
            url = (
                "https://monitoring."
                + env.str("MACHINE_FQDN")
                + "/graylog/api/views/search/"
                + str(randSearchid)
                + "/execute"
            )
            resp = session.post(url, headers=hed)
            if resp.status_code == 201:
                print("Search successfully executed. ")
            else:
                print("Could not execute search. Failure:", resp.status_code)
                print(resp.json())
                exit(1)
            ####
            url = (
                "https://monitoring."
                + env.str("MACHINE_FQDN")
                + "/graylog/api/views/search/metadata"
            )
            content = {
                "id": randSearchid,
                "queries": [
                    {
                        "id": curQuery["id"],
                        "query": curQuery["query"],
                        "timerange": curQuery["timerange"],
                        "filter": None,
                        "search_types": [],
                    }
                    for curQuery in i["state"][list(i["state"].keys())[0]]["widgets"]
                ],
                "parameters": [],
            }
            resp = session.post(url, headers=hed, json=content)
            if resp.status_code == 200:
                print("Search metadata executed. ")
            else:
                print("Could not add metadata for search. Failure:", resp.status_code)
                print(resp.json())
                exit(1)
            ####
            url = "https://monitoring." + env.str("MACHINE_FQDN") + "/graylog/api/views"
            i["search_id"] = str(randSearchid)
            uuidInFile = list(i["state"].keys())[0]
            i["state"][randUuid] = copy.deepcopy(i["state"][uuidInFile])
            del i["state"][uuidInFile]
            del i["state"][randUuid]["widget_mapping"]
            i["state"][randUuid]["widget_mapping"] = {}
            resp = session.post(url, headers=hed, json=i)
            if resp.status_code == 200:
                print("Dashboard successfully added: " + str(i["title"]))
            else:
                print("Could not add dashboard. Failure:", resp.status_code)
                print(resp.json())
                exit(1)
        print("###################################")
        print("WARNING: CURRENTLY THERE IS A MINOR BUG W.R.T. DASHBOARDS, PLEASE READ:")
        print(
            "Graylog dashboards will be empty, you need to open the dashboard, go to a widget, and modify the graylog search query"
        )
        print("[Such as: Remove & Re-Add a single letter]")
        print("Then, the dashboard will work. Make sure to save it.")
        print("###################################")

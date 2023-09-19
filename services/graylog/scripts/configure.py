import json
import logging
import os
import warnings
from time import sleep

import requests
import yaml
from environs import Env, EnvError
from tenacity import retry, stop_after_attempt, wait_random
from yaml.loader import SafeLoader

logging.basicConfig(level="INFO")
logger = logging.getLogger()

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


def configure_slack_notifications():
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
        r = session.post(url, headers=hed, verify=False, data=raw_data.encode("utf-8"))
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
        if noti["title"] == "Graylog " + env.str("MACHINE_FQDN") + " Slack notification"
    ][0]["id"]

    return slackNotificationID


def configure_email_notifications():
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
        if noti["title"] == "Graylog " + env.str("MACHINE_FQDN") + " mail notification"
    ][0]["id"]

    return mailNotificationID


def configure_log_retention():
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


def configure_alerts():
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
            for presentAlert in filter(
                lambda e: e["title"] != "System notification events",
                alreadyPresentAlerts,
            ):
                resp = session.delete(
                    url + "/" + str(presentAlert["id"]), headers=hed, verify=False
                )
                if resp.ok:
                    print("Alert successfully deleted: " + str(presentAlert["title"]))
                else:
                    print(
                        "Could not delete alert. Failure: "
                        + str(resp.status_code)
                        + "!"
                    )
                    print(resp.status_code)
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


def configure_content_packs(session, headers, base_url):
    def get_installation(content_pack):
        logger.debug(f"Getting installations for content pack {content_pack['id']}")
        resp = session.get(
            base_url + "/system/content_packs/" + content_pack["id"] + "/installations"
        )

        if not resp.ok:
            raise RuntimeError(
                f"Unexpected error while getting installations for content pack {content_pack['id']}"
            )

        installations = resp.json()["installations"]

        if len(installations) > 1:
            raise RuntimeError(f"<= 1 installations expected got {len(installations)}")

        return installations[0] if installations else None

    def delete_installation(content_pack, installation):
        logger.debug(f"Deleting installation {installation['_id']}")

        resp = session.delete(
            base_url
            + "/system/content_packs/"
            + content_pack["id"]
            + "/installations/"
            + installation["_id"],
            headers=headers,
        )

        if not resp.ok:
            raise RuntimeError(
                f"Error while deleting installation {installation['_id']} for content pack {content_pack['id']}"
            )

    def create_content_pack_revision(content_pack):
        logger.debug(
            f"Uploading content pack {content_pack['id']} revision {content_pack['rev']}"
        )
        resp = session.post(
            base_url + "/system/content_packs", json=content_pack, headers=headers
        )

        if resp.ok:
            pass
        elif resp.status_code == 400:
            logger.debug(
                f"Content pack {content_pack['id']} revision {content_pack['rev']} is already uploaded"
            )
        else:
            raise RuntimeError(
                f"Unexpected {resp.status_code=} while uploading content pack {content_pack['id']} revision {content_pack['rev']}. Error: {resp.text}"
            )

    def install_content_pack_revision(content_pack):
        logger.debug(
            f"Installing content pack {content_pack['id']} revision {content_pack['rev']}"
        )

        resp = session.post(
            base_url
            + f"/system/content_packs/{content_pack['id']}/{content_pack['rev']}/installations",
            json={"comment": "Installed by configure.py script"},
            headers=headers,
        )

        if not resp.ok:
            raise RuntimeError(f"Unexpected {resp.status_code=} {resp.text=}")

    logger.info("Configuring content packs")

    for file in os.listdir("../data/contentpacks"):
        with open(f"../data/contentpacks/{file}") as f:
            logger.debug(f"Configuring content pack {f.name}")
            content_pack = json.loads(f.read())

        create_content_pack_revision(content_pack)

        installation = get_installation(content_pack)

        if not installation:
            install_content_pack_revision(content_pack)
        elif installation["content_pack_revision"] != content_pack["rev"]:
            delete_installation(content_pack, installation)
            install_content_pack_revision(content_pack)
        else:
            logger.debug(
                "This revision of content pack is already installed. Nothing to do..."
            )

        logging.info(f"{f.name} content pack has been configured")


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
    session.verify = False
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

    # Configure sending email notifications
    if env.str("GRAYLOG_ALERT_MAIL_ADDRESS") != "":
        mailNotificationID = configure_email_notifications()

    # Configure sending Slack notifications
    if env.str("GRAYLOG_SLACK_WEBHOOK_URL") != "":
        slackNotificationID = configure_slack_notifications

    # Configure log retention time
    configure_log_retention()

    # Configure Alerts
    configure_alerts()

    # content pack will create GELF UDP Input
    # NOTE: When you introduce changes, revision number increase is mandatory
    # we cannot use auto loader since it doesn't properly update content packs.
    # Autoloader is only good at loading content packs first time but not updating / adding new ones to existing.
    # https://community.graylog.org/t/update-content-packs-using-autoloading-functionality/6205
    # https://github.com/Graylog2/graylog2-server/issues/14672
    content_pack_base_url = (
        "https://monitoring." + env.str("MACHINE_FQDN") + "/graylog/api"
    )
    configure_content_packs(session, hed, content_pack_base_url)

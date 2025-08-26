# pylint: disable=invalid-name
# pylint: disable=logging-fstring-interpolation

import json
import logging
import os
import sys
import warnings
from time import sleep
from typing import Any, Dict, Optional, Tuple

import requests
import yaml
from environs import Env, EnvError
from requests.exceptions import HTTPError
from requests.sessions import Session
from tenacity import (
    before_log,
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_fixed,
    wait_random,
)
from yaml.loader import SafeLoader

logging.basicConfig(level="INFO")
logger: logging.Logger = logging.getLogger()
warnings.filterwarnings(
    "ignore",
    ".*Adding certificate verification is strongly advised.*",
)

env = Env()
env.read_env("./../.env", recurse=False)

SUPPORTED_GRAYLOG_MAJOR_VERSION: int = 6
MACHINE_FQDN: str = env.str("MACHINE_FQDN")
GRAYLOG_BASE_DOMAIN: str = f"https://monitoring.{MACHINE_FQDN}/graylog"
GRAYLOG_WAIT_ONLINE_TIMEOUT_SEC: int = env.int("GRAYLOG_WAIT_ONLINE_TIMEOUT_SEC", 30)
REQUESTS_AUTH: Tuple[str, str] = (
    env.str("SERVICES_USER"),
    env.str("SERVICES_PASSWORD"),
)
GRAYLOG_SYSLOG_CAPTURE_PORT: int = env.int("GRAYLOG_SYSLOG_CAPTURE_PORT")
GRAYLOG_LOG_MAX_DAYS_IN_STORAGE: int = env.int("GRAYLOG_LOG_MAX_DAYS_IN_STORAGE")
GRAYLOG_LOG_MIN_DAYS_IN_STORAGE: int = env.int("GRAYLOG_LOG_MIN_DAYS_IN_STORAGE")
GRAYLOG_SLACK_WEBHOOK_URL: str = env.str("GRAYLOG_SLACK_WEBHOOK_URL")
GRAYLOG_ALERT_MAIL_ADDRESS: str = env.str("GRAYLOG_ALERT_MAIL_ADDRESS")
GRAYLOG_SLACK_WEBHOOK_ICON_URL: str = env.str("GRAYLOG_SLACK_WEBHOOK_ICON_URL")
GRAYLOG_SLACK_WEBHOOK_CHANNEL: str = env.str("GRAYLOG_SLACK_WEBHOOK_CHANNEL")

assert MACHINE_FQDN
assert REQUESTS_AUTH
assert GRAYLOG_SYSLOG_CAPTURE_PORT
assert GRAYLOG_LOG_MAX_DAYS_IN_STORAGE
assert GRAYLOG_LOG_MIN_DAYS_IN_STORAGE


@retry(
    stop=stop_after_attempt(GRAYLOG_WAIT_ONLINE_TIMEOUT_SEC // 5),
    wait=wait_fixed(5),
    retry=retry_if_exception_type(HTTPError),
    before=before_log(logger, logging.INFO),
)
def wait_graylog_is_online() -> None:
    _r: requests.Response = requests.get(
        GRAYLOG_BASE_DOMAIN + "/api/system",
        auth=REQUESTS_AUTH,
        verify=False,
        timeout=10,
    )
    if _r.status_code == 401:
        raise TypeError(f"Graylog unauthorized HTTP response: {_r}")
    _r.raise_for_status()
    logger.info("Graylog is online")


def validate_graylog_version_is_supported() -> None:
    _r: requests.Response = requests.get(
        GRAYLOG_BASE_DOMAIN + "/api/system",
        auth=REQUESTS_AUTH,
        verify=False,
        timeout=30,
    )
    _r.raise_for_status()
    graylog_version: str = _r.json()["version"]
    major_version: int = int(graylog_version.split(".")[0])
    if major_version != SUPPORTED_GRAYLOG_MAJOR_VERSION:
        raise TypeError(
            f"Graylog major version {major_version} is not supported by this script. "
            f"Supported version is {SUPPORTED_GRAYLOG_MAJOR_VERSION}"
        )


@retry(stop=stop_after_attempt(5), wait=wait_random(min=1, max=10))
def get_graylog_inputs(
    _session: Session, _headers: Dict[str, str], _url: str
) -> requests.Response:
    # We check if graylog has inputs, if not we add a new one
    _r: requests.Response = _session.get(_url, headers=_headers, verify=False)
    # DEBUG
    if _r.status_code == 200:
        print("Successfully send GET /api/system/inputs")
        return _r
    error_message: str = (
        "Error while sending GET /api/system/inputs. Status code of the request : "
        + str(_r.status_code)
        + " "
        + _r.text
    )
    print(error_message)
    raise RuntimeError(error_message)


def configure_email_notifications(_session: requests.Session, _headers: dict) -> str:
    _url = GRAYLOG_BASE_DOMAIN + "/api/events/notifications"
    _r = _session.get(_url, headers=_headers, verify=False)
    if (
        len(
            [
                noti
                for noti in r.json()["notifications"]
                if noti["title"] == "Graylog " + MACHINE_FQDN + " mail notification"
            ]
        )
        == 0
    ):
        raw_data = (
            '{"title":"Graylog '
            + MACHINE_FQDN
            + ' mail notification","description":"","config":{"sender":"","subject":"Graylog event notification: ${event_definition_title}","user_recipients":[],"email_recipients":["'
            + GRAYLOG_ALERT_MAIL_ADDRESS
            + '"],"type":"email-notification-v1"}}'
        )
        _r = _session.post(_url, headers=_headers, data=raw_data, verify=False)
        if _r.status_code == 200:
            print("Mail Notification added with success !")
        else:
            print(
                "Error while adding the Mail Notification. Status code of the request : "
                + str(_r.status_code)
                + " "
                + _r.text
            )
            sys.exit(os.EX_USAGE)
    else:
        print("Graylog Mail Notification already present - skipping...")
    # Keeping notification ID
    _r = _session.get(_url, headers=_headers, verify=False)
    _mail_notification_id = [
        noti
        for noti in _r.json()["notifications"]
        if noti["title"] == "Graylog " + MACHINE_FQDN + " mail notification"
    ][0]["id"]

    return _mail_notification_id


def configure_slack_notification_channel(_session: requests.Session, _hed: dict) -> str:
    # Configure sending Slack notifications
    if GRAYLOG_SLACK_WEBHOOK_URL != "":
        assert GRAYLOG_SLACK_WEBHOOK_CHANNEL
        assert GRAYLOG_SLACK_WEBHOOK_ICON_URL
        print(
            f"Starting Graylock Slack Channel Setup. Assuming:\nGRAYLOG_SLACK_WEBHOOK_URL={GRAYLOG_SLACK_WEBHOOK_URL}\nGRAYLOG_SLACK_WEBHOOK_URL={GRAYLOG_SLACK_WEBHOOK_CHANNEL}\nGRAYLOG_SLACK_WEBHOOK_ICON_URL={GRAYLOG_SLACK_WEBHOOK_ICON_URL}"
        )
        _url = (
            "https://monitoring." + MACHINE_FQDN + "/graylog/api/events/notifications"
        )
        _r = _session.get(_url, headers=_hed, verify=False)
        if (
            len(
                [
                    noti
                    for noti in _r.json()["notifications"]
                    if noti["title"]
                    == "Graylog " + MACHINE_FQDN + " Slack notification"
                ]
            )
            == 0
        ):
            raw_data = (
                '{"title":"Graylog '
                + MACHINE_FQDN
                + """ Slack notification","description":"Slack notification","config": {
	    	    "color": "#FF0000",
	    	    "webhook_url": \""""
                + GRAYLOG_SLACK_WEBHOOK_URL
                + """\",
	    	    "channel": "#"""
                + GRAYLOG_SLACK_WEBHOOK_CHANNEL
                + """\",
                "custom_message":"--- [Event Definition] ---------------------------\\nTitle:       ${event_definition_title}\\nType:        ${event_definition_type}\\n--- [Event] --------------------------------------\\nTimestamp:            ${event.timestamp}\\nMessage:              ${event.message}\\nSource:               ${event.source}\\nKey:                  ${event.key}\\nPriority:             ${event.priority}\\nAlert:                ${event.alert}\\nTimestamp Processing: ${event.timestamp}\\nTimerange Start:      ${event.timerange_start}\\nTimerange End:        ${event.timerange_end}\\nEvent Fields:\\n${foreach event.fields field}\\n${field.key}: ${field.value}\\n${end}\\n${if backlog}\\n--- [Backlog] ------------------------------------\\nLast messages accounting for this alert:\\n${foreach backlog message}\\n"""
                + "https://monitoring."
                + MACHINE_FQDN
                + "/graylog/messages"
                + """/${message.index}/${message.id}\\n${end}${end}\\n",
	    	    "user_name": "Graylog",
	    	    "notify_channel": true,
	    	    "link_names": false,
	    	    "icon_url": \""""
                + GRAYLOG_SLACK_WEBHOOK_ICON_URL
                + """\",
	    	    "icon_emoji": "",
	    	    "backlog_size": 5,
	    	    "type": "slack-notification-v1"}}"""
            )
            _r = _session.post(
                _url, headers=_hed, verify=False, data=raw_data.encode("utf-8")
            )
            if _r.status_code == 200:
                print("Slack Notification added with success !")
                # Keeping notification ID
                _r = _session.get(_url, headers=_hed, verify=False)
                _slack_notification_id = [
                    noti
                    for noti in _r.json()["notifications"]
                    if noti["title"]
                    == "Graylog " + MACHINE_FQDN + " Slack notification"
                ][0]["id"]
                return _slack_notification_id
            print(
                "Error while adding the Slack Notification. Status code of the request : "
                + str(r.status_code)
                + " "
                + r.text
            )
            sys.exit(os.EX_USAGE)
        print("Graylog Slack Notification already present - skipping...")
        _r = _session.get(_url, headers=_hed, verify=False)
        _slack_notification_id = [
            noti
            for noti in _r.json()["notifications"]
            if noti["title"] == "Graylog " + MACHINE_FQDN + " Slack notification"
        ][0]["id"]
        return _slack_notification_id
    return ""


def configure_log_retention(_session: requests.Session, _headers: dict) -> None:
    _url = (
        "https://monitoring." + MACHINE_FQDN + "/graylog/api/system/indices/index_sets"
    )
    _r = _session.get(_url, headers=_headers, verify=False)
    index_of_interest = [
        index
        for index in _r.json()["index_sets"]
        if index["title"] == "Default index set"
    ][0]

    # https://graylog.org/post/understanding-data-tiering-in-60-seconds/
    # https://community.graylog.org/t/graylog-6-0-data-tiering-for-rotation-and-retention/33302
    index_of_interest["use_legacy_rotation"] = False
    index_of_interest["data_tiering"] = {
        "type": "hot_only",
        "index_lifetime_min": f"P{GRAYLOG_LOG_MIN_DAYS_IN_STORAGE}D",
        "index_lifetime_max": f"P{GRAYLOG_LOG_MAX_DAYS_IN_STORAGE}D",
    }
    _url = (
        "https://monitoring." + MACHINE_FQDN + "/graylog/api/system/indices/index_sets"
    )
    raw_data = json.dumps(index_of_interest)
    _r = _session.put(
        _url + "/" + str(index_of_interest["id"]),
        headers=_headers,
        data=raw_data,
        verify=False,
    )
    if _r.status_code == 200:
        print("Log retention time successfully updated !")
    else:
        print(
            "Error updating log retention time! Status code of the request : "
            + str(_r.status_code)
            + " "
            + r.text
        )


def configure_syslog_capture(_session: requests.Session, _headers: dict) -> None:
    try:
        _url = (
            "https://monitoring." + MACHINE_FQDN + "/graylog/api/system/cluster/nodes"
        )
        _r = _session.get(_url, headers=_headers, verify=False).json()
        assert len(_r["nodes"]) == 1
        node_uuid = _r["nodes"][0]["node_id"]
        #
        _url = "https://monitoring." + MACHINE_FQDN + "/graylog/api/system/inputs"
        r2 = _session.get(_url, headers=_headers, verify=False).json()
        if len([i for i in r2["inputs"] if i["title"] == "Syslog"]) == 0:
            raw_data = (
                '{"title":"Syslog","type":"org.graylog2.inputs.syslog.udp.SyslogUDPInput","configuration":{"bind_address":"0.0.0.0","port":'
                + str(GRAYLOG_SYSLOG_CAPTURE_PORT)
                + ',"recv_buffer_size":262144,"number_worker_threads":8,"override_source":null,"force_rdns":false,"allow_override_date":true,"store_full_message":true,"expand_structured_data":false},"global":true,"node":"'
                + node_uuid
                + '"}'
            )
            input_id = _session.post(
                _url, headers=_headers, data=raw_data, verify=False
            ).json()["id"]
            #
            sleep(0.3)
            _url = (
                "https://monitoring."
                + MACHINE_FQDN
                + "/graylog/api/system/inputs/"
                + input_id
                + "/extractors"
            )
            raw_data = '{"title":"Fill container_name","cut_or_copy":"copy","source_field":"application_name","target_field":"container_name","extractor_type":"regex_replace","extractor_config":{"regex":"(^.)","replacement":"Syslog: $1"},"converters":{},"condition_type":"none","condition_value":""}'
            _session.post(_url, headers=_headers, data=raw_data, verify=False)
            print("Graylog Syslog Capture setup successful.")
        else:
            print("Graylog Syslog Capture already present, skipping...")
    except EnvError:
        print("Error setting up graylog syslog capturing.")


def configure_alerts(
    _session: requests.Session,
    _headers: dict,
    _mail_notification_id: Optional[str] = None,
    _slack_notification_id: Optional[str] = None,
) -> None:
    print("Configuring Graylog Alerts...")
    with open("alerts.yaml") as f:
        data = yaml.load(f, Loader=SafeLoader)
        _url = "https://monitoring." + MACHINE_FQDN + "/graylog/api/streams"
        _r = _session.get(_url, headers=_headers, verify=False)
        if _r.status_code == 200:
            streams_list = _r.json()["streams"]
            stream_all_events = [
                i
                for i in streams_list
                if "Stream containing all messages" in i["description"]
                or "default stream" == i["title"].lower()
            ]
            stream_id_for_all_messages = stream_all_events[0]["id"]
        else:
            print(
                "Could not determine ID of stream containing all events. Is graylog misconfigured? Exiting with error!"
            )
            sys.exit(os.EX_USAGE)
        _url = "https://monitoring." + MACHINE_FQDN + "/graylog/api/events/definitions"
        # Deleting existing alerts - this ensures idemptency
        _r = _session.get(
            _url, headers=_headers, params={"per_page": 2500}, verify=False
        )
        if _r.status_code == 200:
            already_present_alerts = _r.json()["event_definitions"]
            for present_alert in filter(
                lambda e: e["title"] != "System notification events",
                already_present_alerts,
            ):
                resp = _session.delete(
                    _url + "/" + str(present_alert["id"]),
                    headers=_headers,
                    verify=False,
                )
                if resp.ok:
                    print("Alert successfully deleted: " + str(present_alert["title"]))
                else:
                    print(
                        "Could not delete alert. Failure: "
                        + str(resp.status_code)
                        + "!"
                    )
                    print(resp.status_code)
                    print(resp.json())
                    sys.exit(os.EX_USAGE)
        for i in data:
            i["notifications"] = []
            if GRAYLOG_ALERT_MAIL_ADDRESS != "" and _mail_notification_id:
                i["notifications"] += [{"notification_id": str(_mail_notification_id)}]
            if GRAYLOG_SLACK_WEBHOOK_URL != "" and _slack_notification_id:
                i["notifications"] += [{"notification_id": str(_slack_notification_id)}]
            i["config"]["streams"] = [str(stream_id_for_all_messages)]
            _url = (
                "https://monitoring."
                + MACHINE_FQDN
                + "/graylog/api/events/definitions?schedule=true"
            )
            resp = _session.post(_url, headers=_headers, json=i, verify=False)
            if resp.status_code == 200:
                print("Alert successfully added: " + str(i["title"]))
            else:
                print("Could not add alert. Failure:", resp.status_code)
                print(resp.json())
                sys.exit(os.EX_USAGE)


def configure_content_packs(
    _session: Session, _headers: Dict[str, str], base_url: str
) -> None:
    def get_installation(content_pack: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        logger.debug(f"Getting installations for content pack {content_pack['id']}")
        resp = _session.get(
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

    def delete_installation(
        content_pack: Dict[str, Any], installation: Dict[str, Any]
    ) -> None:
        logger.debug(f"Deleting installation {installation['_id']}")

        resp = _session.delete(
            base_url
            + "/system/content_packs/"
            + content_pack["id"]
            + "/installations/"
            + installation["_id"],
            headers=_headers,
        )

        if not resp.ok:
            raise RuntimeError(
                f"Error while deleting installation {installation['_id']} for content pack {content_pack['id']}"
            )

    def create_content_pack_revision(content_pack: Dict[str, Any]) -> None:
        logger.debug(
            f"Uploading content pack {content_pack['id']} revision {content_pack['rev']}"
        )
        resp = _session.post(
            base_url + "/system/content_packs", json=content_pack, headers=_headers
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

    def install_content_pack_revision(content_pack: Dict[str, Any]) -> None:
        logger.debug(
            f"Installing content pack {content_pack['id']} revision {content_pack['rev']}"
        )

        resp = _session.post(
            base_url
            + f"/system/content_packs/{content_pack['id']}/{content_pack['rev']}/installations",
            json={"comment": "Installed by configure.py script"},
            headers=_headers,
        )

        if not resp.ok:
            raise RuntimeError(f"Unexpected {resp.status_code=} {resp.text=}")

    logger.info("Configuring content packs")

    for file in os.listdir("../data/contentpacks"):
        with open(f"../data/contentpacks/{file}") as f:
            logger.debug(f"Configuring content pack {file}")
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

        logging.info(f"{file} content pack has been configured")


if __name__ == "__main__":
    wait_graylog_is_online()
    validate_graylog_version_is_supported()

    session = requests.Session()
    session.verify = False
    session.auth = REQUESTS_AUTH  # Graylog username is always "admin"
    hed = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Requested-By": "cli",
    }
    url = "https://monitoring." + MACHINE_FQDN + "/graylog/api/system/inputs"
    r = get_graylog_inputs(session, hed, url)

    configure_log_retention(session, hed)
    configure_syslog_capture(session, hed)
    # Configure sending email notifications
    mail_notification_id = None
    slack_notification_id = None
    if GRAYLOG_ALERT_MAIL_ADDRESS != "":
        mail_notification_id = configure_email_notifications(session, hed)
    if GRAYLOG_SLACK_WEBHOOK_URL != "":
        slack_notification_id = configure_slack_notification_channel(session, hed)
    if mail_notification_id or slack_notification_id:
        # Configure Alerts
        configure_alerts(
            session,
            hed,
            _mail_notification_id=mail_notification_id,
            _slack_notification_id=slack_notification_id,
        )

    # content pack will create GELF UDP Input
    # NOTE: When you introduce changes, revision number increase is mandatory
    # we cannot use auto loader since it doesn't properly update content packs.
    # Autoloader is only good at loading content packs first time but not updating / adding new ones to existing.
    # https://community.graylog.org/t/update-content-packs-using-autoloading-functionality/6205
    # https://github.com/Graylog2/graylog2-server/issues/14672
    content_pack_base_url = "https://monitoring." + MACHINE_FQDN + "/graylog/api"
    configure_content_packs(session, hed, content_pack_base_url)

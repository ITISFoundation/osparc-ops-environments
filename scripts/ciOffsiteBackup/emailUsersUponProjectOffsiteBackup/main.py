import os
import smtplib
import ssl
from uuid import UUID

import pandas as pd
import sqlalchemy as db

#########################################
#######################
#
listOfProjectsCommaSeperatedRaw = os.environ.get("CI_OFFSITE_BACKUP_PROJECTS_TO_BACKUP")
listOfProjects = [i for i in listOfProjectsCommaSeperatedRaw.split(",")]
for i in listOfProjects:
    try:
        uuid_obj = UUID(i, version=4)
    except ValueError:
        print(i, "is not a valid UUIDv4. Exiting.")
        exit(1)
# A list of user IDs you would like to send emails to - these can be found from redis commander
excluded_users = [
    "kuster@itis.swiss",
    "@itis.testing",
]  # can be only part of a mail address
#
#
PG_PASSWORD = os.environ.get("POSTGRES_PASSWORD")
PG_ENDPOINT = (
    os.environ.get("POSTGRES_PUBLIC_HOST") + ":" + os.environ.get("POSTGRES_PORT")
)
PG_DB = os.environ.get("POSTGRES_DB")
PG_USER = os.environ.get("POSTGRES_USER")
pgEngineURL = "postgresql://{user}:{password}@{host}:{port}/{database}".format(
    user=PG_USER,
    password=PG_PASSWORD,
    database=PG_DB,
    host=PG_ENDPOINT.split(":")[0],
    port=int(PG_ENDPOINT.split(":")[1]),
)
engine = db.create_engine(pgEngineURL)
connection = engine.connect()
metadata = db.MetaData()
users_df = pd.read_sql_table("users", con=engine)
projects_df = pd.read_sql_table("projects", con=engine)
#
maskProjectsToBeBackuped = projects_df.uuid.isin(listOfProjects)
listOfProjectOwners = projects_df[maskProjectsToBeBackuped].prj_owner.to_list()
#
#
userid_list = []
name_list = []
email_list = []

for user in listOfProjectOwners:
    user_table = db.Table("users", metadata, autoload=True, autoload_with=engine)
    query = db.select([user_table]).where(user_table.c.id == user)
    result_proxy = connection.execute(query)
    result_set = result_proxy.fetchall()
    if result_set:
        user_data = dict(result_set[0])
        userIsExcluded = False
        for excluded_mail in excluded_users:
            if excluded_mail in user_data["email"]:
                userIsExcluded = True
                break
        if not userIsExcluded:
            if user_data["id"] not in userid_list:
                name_list.append(user_data["name"])
                email_list.append(user_data["email"])
                userid_list.append(user_data["id"])
    else:
        print("User ID:" + str(user) + " not found in database")
#
#
SMTP_HOST = os.environ.get("SMTP_HOST")
SMTP_PORT = os.environ.get("SMTP_PORT")
SMTP_USERNAME = os.environ.get("SMTP_USERNAME")
SMTP_PASSWORD = os.environ.get("SMTP_PASSWORD")
deploymentString = (
    os.environ.get("MACHINE_FQDN") + ", " + os.environ.get("MACHINE_FQDNS")
)
productString = "o²S²PARC / S4L-Web / TI-Planning"
#
context = ssl.create_default_context()

with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
    server.ehlo()  # Can be omitted
    server.starttls(context=context)
    server.ehlo()  # Can be omitted
    server.login(SMTP_USERNAME, SMTP_PASSWORD)
    for name, email, id in zip(name_list, email_list, userid_list):
        print("Sending mail to user:", email)
        maskCurrentUser = projects_df.prj_owner.isin([id])
        message = (
            """Subject: """
            + productString
            + """ : Offsite Backup Notice

\nHi """
            + name
            + """, \n
You are registered with an account on: """
            + str(deploymentString)
            + """.

We'd like to notify you that we have just backed up the following projects with encryption to an off-site storage:



"""
            + ", ".join(
                projects_df[maskProjectsToBeBackuped & maskCurrentUser].name.tolist()
            )
            + """




Cheers,
your friendly """
            + productString
            + """ team"""
        )
        server.sendmail(SMTP_USERNAME, email, message.encode("utf-8"))
        print("Sent mails successfully.")

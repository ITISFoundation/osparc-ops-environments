# Copies S3 data from one bucket to another
### Aimed at robustness, should be able to handle corrupt files or network issues during the copy

### Copies the files locally first, and then to target host (!)


## Install
python3 -m venv venv
. venv/bin/activate
pip install -r requirements.txt

## Run
### Required arguments:
```
python3 main.py SOURCEBUCKET_NAME SOURCEBUCKET_ACCESS SOURCEBUCKET_SECRET ENDPOINT_URL
```
### Copy to local folder
```
mkdir copyDestination
python3 main.py SOURCEBUCKET_NAME SOURCEBUCKET_ACCESS SOURCEBUCKET_SECRET ENDPOINT_URL --downloadfolderlocal ./copyDestination
```
### Copy from one bucket to another
```
python3 main.py SOURCEBUCKET_NAME SOURCEBUCKET_ACCESS SOURCEBUCKET_SECRET ENDPOINT_URL --destinationbucketname XXXXXX --destinationbucketaccess XXXXXX --destinationbucketsecret XXXXXX --destinationendpointurl https://XXXXXX
```

### Copy files given in txt-file from one bucket to another
```
python3 main.py SOURCEBUCKET_NAME SOURCEBUCKET_ACCESS SOURCEBUCKET_SECRET ENDPOINT_URL --downloadfolderlocal ./copyDestination --destinationbucketname XXXXXX --destinationbucketaccess XXXXXX --destinationbucketsecret XXXXXX --destinationendpointurl https://XXXXXX --files filesToBeCopied.txt
```

### Copy files from one bucket to another and give oSparc details (projectID, owner) about failed/corrupt files
1. Download `filesmetadata`, `users` and `projects` pgSQL table in CSV format using adminer
2.
```
python3 main.py SOURCEBUCKET_NAME SOURCEBUCKET_ACCESS SOURCEBUCKET_SECRET ENDPOINT_URL --downloadfolderlocal ./copyDestination --destinationbucketname XXXXXX --destinationbucketaccess XXXXXX --destinationbucketsecret XXXXXX --destinationendpointurl https://XXXXXX --filemetadatacsv filemetadatacsv.csv --projectscsv projects.csv --userscsv users.csv
```

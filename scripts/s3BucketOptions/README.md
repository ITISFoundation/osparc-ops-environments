# Sets permissive bucket CORS actions, necessary for oSparc
### Aimed at robustness, should be able to handle corrupt files or network issues during the copy

### Copies the files locally first, and then to target host (!)


## Install
python3 -m venv venv
. venv/bin/activate
pip install -r requirements.txt

## Run
```
python3 setBucketCORS.py
```
### Required arguments:
```
python3 setBucketCORS.py TARGETBUCKET_NAME TARGETBUCKET_ACCESS TARGETBUCKET_SECRET ENDPOINT_URL
```

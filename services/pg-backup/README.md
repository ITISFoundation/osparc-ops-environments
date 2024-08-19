# PG Backup

Docker service running a postgres backup

## Restore backup

From latest backup
* docker exec [container id] sh restore.sh

From specific backup
* docker exec [container-id] sh restore.sh <timestamp>
  - timestamp=$(date +"%Y-%m-%dT%H:%M:%S")

Source: https://github.com/eeshugerman/postgres-backup-s3/tree/master?tab=readme-ov-file#restore

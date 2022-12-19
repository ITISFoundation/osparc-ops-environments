# Summary

Theses scripts allows you to :
- Easily backup and restore a PGSQL database for the Simcore stack.
- Easily copy the data (from a s3/minio bucket to another s3/minio bucket) from the simcore stack.

##  Manual Database backup
- Run `db-backup.bash`

## Database restore from backup
- We use pgbackup to periodically backup the database into an off-site machine.
- The offsite machine is mounted into `/tank` on osparc-dalco-01 and osparc-master-01
- To restore, copy the desired backup from the tank to a working folder (folder structure organized by year/month)
- Rename the file to `backup.sql.gz`
- Unpack the `.gz` file as such: `gzip -dk backup.sql.gz`
- Shut down all simcore services connecting or connected to the pgSQL database (otherwise, dropping the exisiting DB will fail)
- In `osparc-ops-environments/scripts/migration` run `make .env` and copy `.env` to your workfolder (contains filled in variables from repo.config)
- Run `./db-restore.bash -n` in the folder where `backup.sql` and `.env` are present

This will:
1. DROP the simcoredb database from postgres
2. Load a new simcoredb database from the backup

If you encounter problems:
- Make sure the backup.sql file is correctly mounted into the postgres container spawned and operated by the `db-restore.bash`
- All needed env-vars are properly set and loaded by  `db-restore.bash`
- The postgres container spawned by `db-restore.bash` must be connected to the same docker network as the postgresDB instance (we assume this is `monitored_network`)

## S3 migration

The S3 migration scripts connect to the origin and destination hosts, and copy the data of the desired bucked from the origin to the destination.

### How to proceed
- Update the .env file with the necessary informations.
- Execute ./s3-data-migration.bash to migrate the data or/and ./s3-registry-migration.bash to migrate the registry data.
```
./s3-data-migration.bash
```
and/or
```
./s3-registry-migration.bash
```

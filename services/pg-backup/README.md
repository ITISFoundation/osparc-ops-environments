# PG Backup

- PG backup service do a backup every day at 11pm of simcore PGSQL database in a distant server.
- The backup is done in plain PGSQL format


## Important notes
- Unlike the older system, each simcore stack need his own pg-backup service to be started. E.G for dalco-staging, and dalco production, two pg-backup need to be started, each in the corresponding /deployment/production and /deployment/staging folders.
- PG-backup service needs to be started after simcore-postgres. Otherwise it will fail but the container will stay in a running state (this is caught by e2e-ops)

## Restore backup

- Check that the backup exists
- Stop PGSQL (you can stop simcore)
- Delete pgsql volume (STACK_postgres_data)
```
docker volume rm _postgres_data
```
- Start PGSQL (simcore stack)
- Copy the backup into the container. If the id of the container starts with a5a :
```
docker cp PG_osparc-master.speag.com_simcoredb.05-March-2023.dmp a5a:/
```
- Inside of the container, execute this command
```
createuser -s postgres -U scu
```
- Stop all connections to the current empty database :
1) Connect to psql in sudo mode :
```
su postgres
psql
```
2) Execute a query that will stop all the connections
```
SELECT
	pg_terminate_backend(pg_stat_activity.pid)
FROM
	pg_stat_activity
WHERE
	pg_stat_activity.datname = 'simcoredb'
	AND pid <> pg_backend_pid();
```
- Delete simcore database
```
DROP DATABASE simcoredb;
quit
```
- Finally, restore the DB : 
```
psql simcoredb < /PG_osparc-master.speag.com_simcoredb.05-March-2023.dmp
```
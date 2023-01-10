# PG Backup

- PG backup service do a backup every day at 11pm of simcore PGSQL database in a distant server.

## Important note
- Unlike the older system, each simcore stack need his own pg-backup service to be started. E.G for dalco-staging, and dalco production, two pg-backup need to be started, each in the corresponding /deployment/production and /deployment/staging folders.

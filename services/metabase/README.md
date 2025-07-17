## How to deploy first time

Before deploying metabase first time, make sure that postgres is configured:
1. Generate SQL commands via `make configure_metabase.sql`
2. Execute SQL commands from the script in psql shell
    * you can get one via adminer or by directly connecting to container and executing `psql -U <user> -d <db>`

This can be automated via https://github.com/ITISFoundation/osparc-ops-environments/issues/827

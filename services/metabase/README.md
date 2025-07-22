## How to deploy first time

Before deploying metabase first time, make sure that postgres is configured:
1. Generate SQL commands via `make configure_metabase.sql`
2. Execute SQL commands from the script in psql shell
    * you can get one via adminer or by directly connecting to container and executing `psql -U <user> -d <db>`

This can be automated via https://github.com/ITISFoundation/osparc-ops-environments/issues/827

## Removing metabase from deployment
1. Remove stack from CI pipelines
2. Manuall delete stack
3. Clean up database with sql scripts (generated via metabase's Makefile)

## Extra Configuration (optional)

Setting up email (manual):
* go to admin settings
* go to email
* configure email using SMTP_HOST, SMTP_PASSWORD, SMTP_PORT, SMTP_PROTOCOL, SMTP_USERNAME env from config
  - Note: `FROM NAME` shall potentially clearly indicate deployment (if we use metabase in multiple deployments this helps to avoid confusion)
  - Note: `FROM ADDRESS` use support email (we may consider adding a separate user and mail for metabase later)
  - Note: `REPLY-TO ADDRESS` must NOT be support email. Feel free to choose some of backenders / devops email

Configuring localization (manual):
* go to admin settings
* go to localization
* configure first day of the week to be `Monday`

Note: later these manual steps can be automated via Metabase API calls

/* Delete all open connections to the DB, then delete the DB */

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'simcoredb';
DROP database simcoredb;

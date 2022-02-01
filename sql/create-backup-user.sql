--
-- Setup user backup for taking backups
--
-- Create user backup
CREATE USER backup LOGIN ENCRYPTED PASSWORD 'backup';

-- Grant permissions
GRANT USAGE ON SCHEMA pg_catalog TO backup;

GRANT pg_read_all_settings TO backup;

GRANT EXECUTE ON FUNCTION pg_start_backup(text, boolean, boolean) TO backup;
GRANT EXECUTE ON FUNCTION pg_stop_backup(boolean, boolean) TO backup;
GRANT EXECUTE ON FUNCTION pg_stop_backup() TO backup;

-- check options
GRANT EXECUTE ON FUNCTION pg_create_restore_point(text) TO backup;
GRANT EXECUTE ON FUNCTION pg_switch_wal () TO backup;

-- Grant extra permissions if needed
GRANT EXECUTE ON FUNCTION current_setting(text) TO backup;
GRANT EXECUTE ON FUNCTION pg_is_in_recovery() TO backup;
GRANT EXECUTE ON FUNCTION txid_current() TO backup;
GRANT EXECUTE ON FUNCTION txid_current_snapshot() TO backup;
GRANT EXECUTE ON FUNCTION txid_snapshot_xmax(txid_snapshot) TO backup;

-- amcheck functions grants to backup user
GRANT SELECT ON TABLE pg_catalog.pg_am TO backup;
GRANT SELECT ON TABLE pg_catalog.pg_class TO backup;
GRANT SELECT ON TABLE pg_catalog.pg_database TO backup;
GRANT SELECT ON TABLE pg_catalog.pg_namespace TO backup;
GRANT SELECT ON TABLE pg_catalog.pg_extension TO backup;
GRANT EXECUTE ON FUNCTION bt_index_check(regclass) TO backup;
GRANT EXECUTE ON FUNCTION bt_index_check(regclass, bool) TO backup;
GRANT SELECT ON TABLE pg_catalog.pg_database TO backup;

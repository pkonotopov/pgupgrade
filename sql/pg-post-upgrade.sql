-- Update all extensions

DO $$ DECLARE e RECORD;
    BEGIN FOR e IN select extname from pg_catalog.pg_extension
    LOOP EXECUTE format('ALTER EXTENSION %I UPDATE;', e.extname);
END LOOP; END $$;

-- Run VACUUM ANALYZE
-- VACUUM (VERBOSE, ANALYZE);
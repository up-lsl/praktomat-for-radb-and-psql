DROP SCHEMA public CASCADE;
GRANT CONNECT ON DATABASE $dbName TO psqluserread;
CREATE SCHEMA $schemaName AUTHORIZATION psqlusermanager;
ALTER DATABASE $dbName SET search_path TO $schemaName;

GRANT USAGE  ON SCHEMA $schemaName TO psqluserread;
GRANT CREATE ON SCHEMA $schemaName TO psqlusermanager;

ALTER DEFAULT PRIVILEGES FOR ROLE psqlusermanager
GRANT SELECT                           ON TABLES TO psqluserread;  -- only read

ALTER DEFAULT PRIVILEGES FOR ROLE psqlusermanager
GRANT INSERT, UPDATE, DELETE, TRUNCATE ON TABLES TO psqluserwrite;  -- + write, TRUNCATE optional

ALTER DEFAULT PRIVILEGES FOR ROLE psqlusermanager
GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO psqluserwrite;  -- SELECT, UPDATE are optional 

CREATE ROLE $dbadminuser LOGIN SUPERUSER PASSWORD '$dbadminpass';

CREATE USER $dbmanageruser WITH LOGIN PASSWORD '$dbmanagerpass';
CREATE USER $dbwriteuser   WITH LOGIN PASSWORD '$dbwritepass';
CREATE USER $dbreaduser    WITH LOGIN PASSWORD '$dbreadpass';

GRANT $dbreaduser    TO $dbwriteuser;
GRANT $dbwriteuser   TO $dbmanageruser;

REVOKE ALL PRIVILEGES ON DATABASE "postgres" from $dbreaduser;
REVOKE ALL PRIVILEGES ON DATABASE "postgres" from $dbwriteuser;
REVOKE ALL PRIVILEGES ON DATABASE "postgres" from $dbmanageruser;
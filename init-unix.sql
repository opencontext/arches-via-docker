UPDATE pg_database SET datistemplate='false' WHERE datname='template_postgis';
DROP DATABASE IF EXISTS template_postgis;
CREATE DATABASE template_postgis WITH ENCODING 'UTF8';
UPDATE pg_database SET datistemplate='true' WHERE datname='template_postgis';

\c template_postgis

CREATE EXTENSION IF NOT EXISTS postgis;
GRANT ALL ON geometry_columns TO PUBLIC;
GRANT ALL ON geography_columns TO PUBLIC;
GRANT ALL ON spatial_ref_sys TO PUBLIC;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
# create user and database for aquagis-api
db_user_exists=`sudo -u postgres psql postgres -tAc "select 1 from pg_roles where rolname='gis'"`
if [ "$db_user_exists" != "1" ]; then
    sudo -u postgres createuser -s gis
    sudo -u gis createdb -E UTF-8 -O gis aquagis_db
    sudo -u gis createdb -E UTF-8 -O gis aquagis_test
    # add btree_gist extension
    sudo -u gis psql -c "create extension btree_gist" aquagis_db
    sudo -u gis psql -c "create extension btree_gist" aquagis_test
fi


# install PostgreSQL functions
sudo -u gis psql -d aquagis_db -f db/functions/functions.sql
################################################################################
# *IF* you want a vagrant image which supports replication (or perhaps you're
# using this script to provision some other server and want replication), then
# uncomment the following lines (until popd) and comment out the one above
# (functions.sql).
################################################################################
pushd db/functions
sudo -u gis make
sudo -u gis psql aquagis_db -c "CREATE OR REPLACE FUNCTION tile_for_point(int4, int4) RETURNS int8 AS '/srv/openstreetmap-website/db/functions/libpgosm.so', 'tile_for_point' LANGUAGE C STRICT"
sudo -u gis psql aquagis_db -c "CREATE OR REPLACE FUNCTION xid_to_int4(xid) RETURNS int4 AS '/srv/openstreetmap-website/db/functions/libpgosm.so', 'xid_to_int4' LANGUAGE C STRICT"
popd


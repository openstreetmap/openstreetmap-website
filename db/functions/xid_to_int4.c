#include <postgres.h>
#include <fmgr.h>

Datum
xid_to_int4(PG_FUNCTION_ARGS)
{
   PG_RETURN_INT32(DatumGetTransactionId(0));
}

PG_FUNCTION_INFO_V1(xid_to_int4);

/*
 * To bind this into PGSQL, try something like:
 *
 * CREATE FUNCTION xid_to_int4(xid) RETURNS int4
 *  AS '/path/to/rails-port/db/functions/libpgosm', 'xid_to_int4'
 *  LANGUAGE C IMMUTABLE STRICT;
 *
 * (without all the *s)
 */

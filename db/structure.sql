--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: gbtreekey16; Type: SHELL TYPE; Schema: public; Owner: -
--

CREATE TYPE gbtreekey16;


--
-- Name: gbtreekey16_in(cstring); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbtreekey16_in(cstring) RETURNS gbtreekey16
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbtreekey_in';


--
-- Name: gbtreekey16_out(gbtreekey16); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbtreekey16_out(gbtreekey16) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbtreekey_out';


--
-- Name: gbtreekey16; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE gbtreekey16 (
    INTERNALLENGTH = 16,
    INPUT = gbtreekey16_in,
    OUTPUT = gbtreekey16_out,
    ALIGNMENT = int4,
    STORAGE = plain
);


--
-- Name: gbtreekey32; Type: SHELL TYPE; Schema: public; Owner: -
--

CREATE TYPE gbtreekey32;


--
-- Name: gbtreekey32_in(cstring); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbtreekey32_in(cstring) RETURNS gbtreekey32
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbtreekey_in';


--
-- Name: gbtreekey32_out(gbtreekey32); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbtreekey32_out(gbtreekey32) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbtreekey_out';


--
-- Name: gbtreekey32; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE gbtreekey32 (
    INTERNALLENGTH = 32,
    INPUT = gbtreekey32_in,
    OUTPUT = gbtreekey32_out,
    ALIGNMENT = int4,
    STORAGE = plain
);


--
-- Name: gbtreekey4; Type: SHELL TYPE; Schema: public; Owner: -
--

CREATE TYPE gbtreekey4;


--
-- Name: gbtreekey4_in(cstring); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbtreekey4_in(cstring) RETURNS gbtreekey4
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbtreekey_in';


--
-- Name: gbtreekey4_out(gbtreekey4); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbtreekey4_out(gbtreekey4) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbtreekey_out';


--
-- Name: gbtreekey4; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE gbtreekey4 (
    INTERNALLENGTH = 4,
    INPUT = gbtreekey4_in,
    OUTPUT = gbtreekey4_out,
    ALIGNMENT = int4,
    STORAGE = plain
);


--
-- Name: gbtreekey8; Type: SHELL TYPE; Schema: public; Owner: -
--

CREATE TYPE gbtreekey8;


--
-- Name: gbtreekey8_in(cstring); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbtreekey8_in(cstring) RETURNS gbtreekey8
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbtreekey_in';


--
-- Name: gbtreekey8_out(gbtreekey8); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbtreekey8_out(gbtreekey8) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbtreekey_out';


--
-- Name: gbtreekey8; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE gbtreekey8 (
    INTERNALLENGTH = 8,
    INPUT = gbtreekey8_in,
    OUTPUT = gbtreekey8_out,
    ALIGNMENT = int4,
    STORAGE = plain
);


--
-- Name: gbtreekey_var; Type: SHELL TYPE; Schema: public; Owner: -
--

CREATE TYPE gbtreekey_var;


--
-- Name: gbtreekey_var_in(cstring); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbtreekey_var_in(cstring) RETURNS gbtreekey_var
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbtreekey_in';


--
-- Name: gbtreekey_var_out(gbtreekey_var); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbtreekey_var_out(gbtreekey_var) RETURNS cstring
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbtreekey_out';


--
-- Name: gbtreekey_var; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE gbtreekey_var (
    INTERNALLENGTH = variable,
    INPUT = gbtreekey_var_in,
    OUTPUT = gbtreekey_var_out,
    ALIGNMENT = int4,
    STORAGE = extended
);


--
-- Name: gpx_visibility_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE gpx_visibility_enum AS ENUM (
    'private',
    'public',
    'trackable',
    'identifiable'
);


--
-- Name: nwr_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE nwr_enum AS ENUM (
    'Node',
    'Way',
    'Relation'
);


--
-- Name: user_role_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE user_role_enum AS ENUM (
    'administrator',
    'moderator'
);


--
-- Name: user_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE user_status_enum AS ENUM (
    'pending',
    'active',
    'confirmed',
    'suspended',
    'deleted'
);


--
-- Name: gbt_bit_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bit_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bit_compress';


--
-- Name: gbt_bit_consistent(internal, bit, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bit_consistent(internal, bit, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bit_consistent';


--
-- Name: gbt_bit_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bit_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bit_penalty';


--
-- Name: gbt_bit_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bit_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bit_picksplit';


--
-- Name: gbt_bit_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bit_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bit_same';


--
-- Name: gbt_bit_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bit_union(bytea, internal) RETURNS gbtreekey_var
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bit_union';


--
-- Name: gbt_bpchar_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bpchar_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bpchar_compress';


--
-- Name: gbt_bpchar_consistent(internal, character, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bpchar_consistent(internal, character, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bpchar_consistent';


--
-- Name: gbt_bytea_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bytea_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bytea_compress';


--
-- Name: gbt_bytea_consistent(internal, bytea, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bytea_consistent(internal, bytea, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bytea_consistent';


--
-- Name: gbt_bytea_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bytea_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bytea_penalty';


--
-- Name: gbt_bytea_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bytea_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bytea_picksplit';


--
-- Name: gbt_bytea_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bytea_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bytea_same';


--
-- Name: gbt_bytea_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_bytea_union(bytea, internal) RETURNS gbtreekey_var
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_bytea_union';


--
-- Name: gbt_cash_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_cash_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_cash_compress';


--
-- Name: gbt_cash_consistent(internal, money, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_cash_consistent(internal, money, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_cash_consistent';


--
-- Name: gbt_cash_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_cash_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_cash_penalty';


--
-- Name: gbt_cash_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_cash_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_cash_picksplit';


--
-- Name: gbt_cash_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_cash_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_cash_same';


--
-- Name: gbt_cash_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_cash_union(bytea, internal) RETURNS gbtreekey8
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_cash_union';


--
-- Name: gbt_date_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_date_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_date_compress';


--
-- Name: gbt_date_consistent(internal, date, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_date_consistent(internal, date, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_date_consistent';


--
-- Name: gbt_date_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_date_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_date_penalty';


--
-- Name: gbt_date_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_date_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_date_picksplit';


--
-- Name: gbt_date_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_date_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_date_same';


--
-- Name: gbt_date_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_date_union(bytea, internal) RETURNS gbtreekey8
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_date_union';


--
-- Name: gbt_decompress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_decompress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_decompress';


--
-- Name: gbt_float4_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float4_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float4_compress';


--
-- Name: gbt_float4_consistent(internal, real, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float4_consistent(internal, real, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float4_consistent';


--
-- Name: gbt_float4_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float4_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float4_penalty';


--
-- Name: gbt_float4_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float4_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float4_picksplit';


--
-- Name: gbt_float4_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float4_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float4_same';


--
-- Name: gbt_float4_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float4_union(bytea, internal) RETURNS gbtreekey8
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float4_union';


--
-- Name: gbt_float8_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float8_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float8_compress';


--
-- Name: gbt_float8_consistent(internal, double precision, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float8_consistent(internal, double precision, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float8_consistent';


--
-- Name: gbt_float8_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float8_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float8_penalty';


--
-- Name: gbt_float8_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float8_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float8_picksplit';


--
-- Name: gbt_float8_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float8_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float8_same';


--
-- Name: gbt_float8_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_float8_union(bytea, internal) RETURNS gbtreekey16
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_float8_union';


--
-- Name: gbt_inet_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_inet_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_inet_compress';


--
-- Name: gbt_inet_consistent(internal, inet, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_inet_consistent(internal, inet, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_inet_consistent';


--
-- Name: gbt_inet_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_inet_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_inet_penalty';


--
-- Name: gbt_inet_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_inet_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_inet_picksplit';


--
-- Name: gbt_inet_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_inet_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_inet_same';


--
-- Name: gbt_inet_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_inet_union(bytea, internal) RETURNS gbtreekey16
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_inet_union';


--
-- Name: gbt_int2_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int2_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int2_compress';


--
-- Name: gbt_int2_consistent(internal, smallint, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int2_consistent(internal, smallint, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int2_consistent';


--
-- Name: gbt_int2_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int2_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int2_penalty';


--
-- Name: gbt_int2_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int2_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int2_picksplit';


--
-- Name: gbt_int2_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int2_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int2_same';


--
-- Name: gbt_int2_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int2_union(bytea, internal) RETURNS gbtreekey4
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int2_union';


--
-- Name: gbt_int4_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int4_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int4_compress';


--
-- Name: gbt_int4_consistent(internal, integer, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int4_consistent(internal, integer, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int4_consistent';


--
-- Name: gbt_int4_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int4_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int4_penalty';


--
-- Name: gbt_int4_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int4_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int4_picksplit';


--
-- Name: gbt_int4_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int4_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int4_same';


--
-- Name: gbt_int4_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int4_union(bytea, internal) RETURNS gbtreekey8
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int4_union';


--
-- Name: gbt_int8_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int8_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int8_compress';


--
-- Name: gbt_int8_consistent(internal, bigint, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int8_consistent(internal, bigint, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int8_consistent';


--
-- Name: gbt_int8_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int8_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int8_penalty';


--
-- Name: gbt_int8_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int8_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int8_picksplit';


--
-- Name: gbt_int8_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int8_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int8_same';


--
-- Name: gbt_int8_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_int8_union(bytea, internal) RETURNS gbtreekey16
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_int8_union';


--
-- Name: gbt_intv_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_intv_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_intv_compress';


--
-- Name: gbt_intv_consistent(internal, interval, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_intv_consistent(internal, interval, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_intv_consistent';


--
-- Name: gbt_intv_decompress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_intv_decompress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_intv_decompress';


--
-- Name: gbt_intv_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_intv_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_intv_penalty';


--
-- Name: gbt_intv_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_intv_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_intv_picksplit';


--
-- Name: gbt_intv_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_intv_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_intv_same';


--
-- Name: gbt_intv_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_intv_union(bytea, internal) RETURNS gbtreekey32
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_intv_union';


--
-- Name: gbt_macad_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_macad_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_macad_compress';


--
-- Name: gbt_macad_consistent(internal, macaddr, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_macad_consistent(internal, macaddr, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_macad_consistent';


--
-- Name: gbt_macad_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_macad_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_macad_penalty';


--
-- Name: gbt_macad_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_macad_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_macad_picksplit';


--
-- Name: gbt_macad_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_macad_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_macad_same';


--
-- Name: gbt_macad_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_macad_union(bytea, internal) RETURNS gbtreekey16
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_macad_union';


--
-- Name: gbt_numeric_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_numeric_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_numeric_compress';


--
-- Name: gbt_numeric_consistent(internal, numeric, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_numeric_consistent(internal, numeric, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_numeric_consistent';


--
-- Name: gbt_numeric_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_numeric_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_numeric_penalty';


--
-- Name: gbt_numeric_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_numeric_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_numeric_picksplit';


--
-- Name: gbt_numeric_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_numeric_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_numeric_same';


--
-- Name: gbt_numeric_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_numeric_union(bytea, internal) RETURNS gbtreekey_var
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_numeric_union';


--
-- Name: gbt_oid_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_oid_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_oid_compress';


--
-- Name: gbt_oid_consistent(internal, oid, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_oid_consistent(internal, oid, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_oid_consistent';


--
-- Name: gbt_oid_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_oid_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_oid_penalty';


--
-- Name: gbt_oid_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_oid_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_oid_picksplit';


--
-- Name: gbt_oid_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_oid_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_oid_same';


--
-- Name: gbt_oid_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_oid_union(bytea, internal) RETURNS gbtreekey8
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_oid_union';


--
-- Name: gbt_text_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_text_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_text_compress';


--
-- Name: gbt_text_consistent(internal, text, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_text_consistent(internal, text, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_text_consistent';


--
-- Name: gbt_text_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_text_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_text_penalty';


--
-- Name: gbt_text_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_text_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_text_picksplit';


--
-- Name: gbt_text_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_text_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_text_same';


--
-- Name: gbt_text_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_text_union(bytea, internal) RETURNS gbtreekey_var
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_text_union';


--
-- Name: gbt_time_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_time_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_time_compress';


--
-- Name: gbt_time_consistent(internal, time without time zone, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_time_consistent(internal, time without time zone, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_time_consistent';


--
-- Name: gbt_time_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_time_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_time_penalty';


--
-- Name: gbt_time_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_time_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_time_picksplit';


--
-- Name: gbt_time_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_time_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_time_same';


--
-- Name: gbt_time_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_time_union(bytea, internal) RETURNS gbtreekey16
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_time_union';


--
-- Name: gbt_timetz_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_timetz_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_timetz_compress';


--
-- Name: gbt_timetz_consistent(internal, time with time zone, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_timetz_consistent(internal, time with time zone, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_timetz_consistent';


--
-- Name: gbt_ts_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_ts_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_ts_compress';


--
-- Name: gbt_ts_consistent(internal, timestamp without time zone, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_ts_consistent(internal, timestamp without time zone, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_ts_consistent';


--
-- Name: gbt_ts_penalty(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_ts_penalty(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_ts_penalty';


--
-- Name: gbt_ts_picksplit(internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_ts_picksplit(internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_ts_picksplit';


--
-- Name: gbt_ts_same(internal, internal, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_ts_same(internal, internal, internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_ts_same';


--
-- Name: gbt_ts_union(bytea, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_ts_union(bytea, internal) RETURNS gbtreekey16
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_ts_union';


--
-- Name: gbt_tstz_compress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_tstz_compress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_tstz_compress';


--
-- Name: gbt_tstz_consistent(internal, timestamp with time zone, smallint, oid, internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_tstz_consistent(internal, timestamp with time zone, smallint, oid, internal) RETURNS boolean
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_tstz_consistent';


--
-- Name: gbt_var_decompress(internal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION gbt_var_decompress(internal) RETURNS internal
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/btree_gist', 'gbt_var_decompress';


--
-- Name: maptile_for_point(bigint, bigint, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION maptile_for_point(bigint, bigint, integer) RETURNS integer
    LANGUAGE c STRICT
    AS '/srv/www/master.osm.compton.nu/db/functions/libpgosm.so', 'maptile_for_point';


--
-- Name: tile_for_point(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION tile_for_point(integer, integer) RETURNS bigint
    LANGUAGE c STRICT
    AS '/srv/www/master.osm.compton.nu/db/functions/libpgosm.so', 'tile_for_point';


--
-- Name: xid_to_int4(xid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION xid_to_int4(xid) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '/srv/www/master.osm.compton.nu/db/functions/libpgosm.so', 'xid_to_int4';


--
-- Name: gist_bit_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_bit_ops USING gist;


--
-- Name: gist_bit_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_bit_ops
    DEFAULT FOR TYPE bit USING gist AS
    STORAGE gbtreekey_var ,
    OPERATOR 1 <(bit,bit) ,
    OPERATOR 2 <=(bit,bit) ,
    OPERATOR 3 =(bit,bit) ,
    OPERATOR 4 >=(bit,bit) ,
    OPERATOR 5 >(bit,bit) ,
    FUNCTION 1 gbt_bit_consistent(internal,bit,smallint,oid,internal) ,
    FUNCTION 2 gbt_bit_union(bytea,internal) ,
    FUNCTION 3 gbt_bit_compress(internal) ,
    FUNCTION 4 gbt_var_decompress(internal) ,
    FUNCTION 5 gbt_bit_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_bit_picksplit(internal,internal) ,
    FUNCTION 7 gbt_bit_same(internal,internal,internal);


--
-- Name: gist_bpchar_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_bpchar_ops USING gist;


--
-- Name: gist_bpchar_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_bpchar_ops
    DEFAULT FOR TYPE character USING gist AS
    STORAGE gbtreekey_var ,
    OPERATOR 1 <(character,character) ,
    OPERATOR 2 <=(character,character) ,
    OPERATOR 3 =(character,character) ,
    OPERATOR 4 >=(character,character) ,
    OPERATOR 5 >(character,character) ,
    FUNCTION 1 gbt_bpchar_consistent(internal,character,smallint,oid,internal) ,
    FUNCTION 2 gbt_text_union(bytea,internal) ,
    FUNCTION 3 gbt_bpchar_compress(internal) ,
    FUNCTION 4 gbt_var_decompress(internal) ,
    FUNCTION 5 gbt_text_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_text_picksplit(internal,internal) ,
    FUNCTION 7 gbt_text_same(internal,internal,internal);


--
-- Name: gist_bytea_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_bytea_ops USING gist;


--
-- Name: gist_bytea_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_bytea_ops
    DEFAULT FOR TYPE bytea USING gist AS
    STORAGE gbtreekey_var ,
    OPERATOR 1 <(bytea,bytea) ,
    OPERATOR 2 <=(bytea,bytea) ,
    OPERATOR 3 =(bytea,bytea) ,
    OPERATOR 4 >=(bytea,bytea) ,
    OPERATOR 5 >(bytea,bytea) ,
    FUNCTION 1 gbt_bytea_consistent(internal,bytea,smallint,oid,internal) ,
    FUNCTION 2 gbt_bytea_union(bytea,internal) ,
    FUNCTION 3 gbt_bytea_compress(internal) ,
    FUNCTION 4 gbt_var_decompress(internal) ,
    FUNCTION 5 gbt_bytea_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_bytea_picksplit(internal,internal) ,
    FUNCTION 7 gbt_bytea_same(internal,internal,internal);


--
-- Name: gist_cash_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_cash_ops USING gist;


--
-- Name: gist_cash_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_cash_ops
    DEFAULT FOR TYPE money USING gist AS
    STORAGE gbtreekey16 ,
    OPERATOR 1 <(money,money) ,
    OPERATOR 2 <=(money,money) ,
    OPERATOR 3 =(money,money) ,
    OPERATOR 4 >=(money,money) ,
    OPERATOR 5 >(money,money) ,
    FUNCTION 1 gbt_cash_consistent(internal,money,smallint,oid,internal) ,
    FUNCTION 2 gbt_cash_union(bytea,internal) ,
    FUNCTION 3 gbt_cash_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_cash_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_cash_picksplit(internal,internal) ,
    FUNCTION 7 gbt_cash_same(internal,internal,internal);


--
-- Name: gist_cidr_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_cidr_ops USING gist;


--
-- Name: gist_cidr_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_cidr_ops
    DEFAULT FOR TYPE cidr USING gist AS
    STORAGE gbtreekey16 ,
    OPERATOR 1 <(inet,inet) ,
    OPERATOR 2 <=(inet,inet) ,
    OPERATOR 3 =(inet,inet) ,
    OPERATOR 4 >=(inet,inet) ,
    OPERATOR 5 >(inet,inet) ,
    FUNCTION 1 gbt_inet_consistent(internal,inet,smallint,oid,internal) ,
    FUNCTION 2 gbt_inet_union(bytea,internal) ,
    FUNCTION 3 gbt_inet_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_inet_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_inet_picksplit(internal,internal) ,
    FUNCTION 7 gbt_inet_same(internal,internal,internal);


--
-- Name: gist_date_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_date_ops USING gist;


--
-- Name: gist_date_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_date_ops
    DEFAULT FOR TYPE date USING gist AS
    STORAGE gbtreekey8 ,
    OPERATOR 1 <(date,date) ,
    OPERATOR 2 <=(date,date) ,
    OPERATOR 3 =(date,date) ,
    OPERATOR 4 >=(date,date) ,
    OPERATOR 5 >(date,date) ,
    FUNCTION 1 gbt_date_consistent(internal,date,smallint,oid,internal) ,
    FUNCTION 2 gbt_date_union(bytea,internal) ,
    FUNCTION 3 gbt_date_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_date_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_date_picksplit(internal,internal) ,
    FUNCTION 7 gbt_date_same(internal,internal,internal);


--
-- Name: gist_float4_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_float4_ops USING gist;


--
-- Name: gist_float4_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_float4_ops
    DEFAULT FOR TYPE real USING gist AS
    STORAGE gbtreekey8 ,
    OPERATOR 1 <(real,real) ,
    OPERATOR 2 <=(real,real) ,
    OPERATOR 3 =(real,real) ,
    OPERATOR 4 >=(real,real) ,
    OPERATOR 5 >(real,real) ,
    FUNCTION 1 gbt_float4_consistent(internal,real,smallint,oid,internal) ,
    FUNCTION 2 gbt_float4_union(bytea,internal) ,
    FUNCTION 3 gbt_float4_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_float4_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_float4_picksplit(internal,internal) ,
    FUNCTION 7 gbt_float4_same(internal,internal,internal);


--
-- Name: gist_float8_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_float8_ops USING gist;


--
-- Name: gist_float8_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_float8_ops
    DEFAULT FOR TYPE double precision USING gist AS
    STORAGE gbtreekey16 ,
    OPERATOR 1 <(double precision,double precision) ,
    OPERATOR 2 <=(double precision,double precision) ,
    OPERATOR 3 =(double precision,double precision) ,
    OPERATOR 4 >=(double precision,double precision) ,
    OPERATOR 5 >(double precision,double precision) ,
    FUNCTION 1 gbt_float8_consistent(internal,double precision,smallint,oid,internal) ,
    FUNCTION 2 gbt_float8_union(bytea,internal) ,
    FUNCTION 3 gbt_float8_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_float8_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_float8_picksplit(internal,internal) ,
    FUNCTION 7 gbt_float8_same(internal,internal,internal);


--
-- Name: gist_inet_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_inet_ops USING gist;


--
-- Name: gist_inet_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_inet_ops
    DEFAULT FOR TYPE inet USING gist AS
    STORAGE gbtreekey16 ,
    OPERATOR 1 <(inet,inet) ,
    OPERATOR 2 <=(inet,inet) ,
    OPERATOR 3 =(inet,inet) ,
    OPERATOR 4 >=(inet,inet) ,
    OPERATOR 5 >(inet,inet) ,
    FUNCTION 1 gbt_inet_consistent(internal,inet,smallint,oid,internal) ,
    FUNCTION 2 gbt_inet_union(bytea,internal) ,
    FUNCTION 3 gbt_inet_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_inet_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_inet_picksplit(internal,internal) ,
    FUNCTION 7 gbt_inet_same(internal,internal,internal);


--
-- Name: gist_int2_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_int2_ops USING gist;


--
-- Name: gist_int2_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_int2_ops
    DEFAULT FOR TYPE smallint USING gist AS
    STORAGE gbtreekey4 ,
    OPERATOR 1 <(smallint,smallint) ,
    OPERATOR 2 <=(smallint,smallint) ,
    OPERATOR 3 =(smallint,smallint) ,
    OPERATOR 4 >=(smallint,smallint) ,
    OPERATOR 5 >(smallint,smallint) ,
    FUNCTION 1 gbt_int2_consistent(internal,smallint,smallint,oid,internal) ,
    FUNCTION 2 gbt_int2_union(bytea,internal) ,
    FUNCTION 3 gbt_int2_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_int2_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_int2_picksplit(internal,internal) ,
    FUNCTION 7 gbt_int2_same(internal,internal,internal);


--
-- Name: gist_int4_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_int4_ops USING gist;


--
-- Name: gist_int4_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_int4_ops
    DEFAULT FOR TYPE integer USING gist AS
    STORAGE gbtreekey8 ,
    OPERATOR 1 <(integer,integer) ,
    OPERATOR 2 <=(integer,integer) ,
    OPERATOR 3 =(integer,integer) ,
    OPERATOR 4 >=(integer,integer) ,
    OPERATOR 5 >(integer,integer) ,
    FUNCTION 1 gbt_int4_consistent(internal,integer,smallint,oid,internal) ,
    FUNCTION 2 gbt_int4_union(bytea,internal) ,
    FUNCTION 3 gbt_int4_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_int4_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_int4_picksplit(internal,internal) ,
    FUNCTION 7 gbt_int4_same(internal,internal,internal);


--
-- Name: gist_int8_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_int8_ops USING gist;


--
-- Name: gist_int8_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_int8_ops
    DEFAULT FOR TYPE bigint USING gist AS
    STORAGE gbtreekey16 ,
    OPERATOR 1 <(bigint,bigint) ,
    OPERATOR 2 <=(bigint,bigint) ,
    OPERATOR 3 =(bigint,bigint) ,
    OPERATOR 4 >=(bigint,bigint) ,
    OPERATOR 5 >(bigint,bigint) ,
    FUNCTION 1 gbt_int8_consistent(internal,bigint,smallint,oid,internal) ,
    FUNCTION 2 gbt_int8_union(bytea,internal) ,
    FUNCTION 3 gbt_int8_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_int8_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_int8_picksplit(internal,internal) ,
    FUNCTION 7 gbt_int8_same(internal,internal,internal);


--
-- Name: gist_interval_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_interval_ops USING gist;


--
-- Name: gist_interval_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_interval_ops
    DEFAULT FOR TYPE interval USING gist AS
    STORAGE gbtreekey32 ,
    OPERATOR 1 <(interval,interval) ,
    OPERATOR 2 <=(interval,interval) ,
    OPERATOR 3 =(interval,interval) ,
    OPERATOR 4 >=(interval,interval) ,
    OPERATOR 5 >(interval,interval) ,
    FUNCTION 1 gbt_intv_consistent(internal,interval,smallint,oid,internal) ,
    FUNCTION 2 gbt_intv_union(bytea,internal) ,
    FUNCTION 3 gbt_intv_compress(internal) ,
    FUNCTION 4 gbt_intv_decompress(internal) ,
    FUNCTION 5 gbt_intv_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_intv_picksplit(internal,internal) ,
    FUNCTION 7 gbt_intv_same(internal,internal,internal);


--
-- Name: gist_macaddr_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_macaddr_ops USING gist;


--
-- Name: gist_macaddr_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_macaddr_ops
    DEFAULT FOR TYPE macaddr USING gist AS
    STORAGE gbtreekey16 ,
    OPERATOR 1 <(macaddr,macaddr) ,
    OPERATOR 2 <=(macaddr,macaddr) ,
    OPERATOR 3 =(macaddr,macaddr) ,
    OPERATOR 4 >=(macaddr,macaddr) ,
    OPERATOR 5 >(macaddr,macaddr) ,
    FUNCTION 1 gbt_macad_consistent(internal,macaddr,smallint,oid,internal) ,
    FUNCTION 2 gbt_macad_union(bytea,internal) ,
    FUNCTION 3 gbt_macad_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_macad_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_macad_picksplit(internal,internal) ,
    FUNCTION 7 gbt_macad_same(internal,internal,internal);


--
-- Name: gist_numeric_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_numeric_ops USING gist;


--
-- Name: gist_numeric_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_numeric_ops
    DEFAULT FOR TYPE numeric USING gist AS
    STORAGE gbtreekey_var ,
    OPERATOR 1 <(numeric,numeric) ,
    OPERATOR 2 <=(numeric,numeric) ,
    OPERATOR 3 =(numeric,numeric) ,
    OPERATOR 4 >=(numeric,numeric) ,
    OPERATOR 5 >(numeric,numeric) ,
    FUNCTION 1 gbt_numeric_consistent(internal,numeric,smallint,oid,internal) ,
    FUNCTION 2 gbt_numeric_union(bytea,internal) ,
    FUNCTION 3 gbt_numeric_compress(internal) ,
    FUNCTION 4 gbt_var_decompress(internal) ,
    FUNCTION 5 gbt_numeric_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_numeric_picksplit(internal,internal) ,
    FUNCTION 7 gbt_numeric_same(internal,internal,internal);


--
-- Name: gist_oid_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_oid_ops USING gist;


--
-- Name: gist_oid_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_oid_ops
    DEFAULT FOR TYPE oid USING gist AS
    STORAGE gbtreekey8 ,
    OPERATOR 1 <(oid,oid) ,
    OPERATOR 2 <=(oid,oid) ,
    OPERATOR 3 =(oid,oid) ,
    OPERATOR 4 >=(oid,oid) ,
    OPERATOR 5 >(oid,oid) ,
    FUNCTION 1 gbt_oid_consistent(internal,oid,smallint,oid,internal) ,
    FUNCTION 2 gbt_oid_union(bytea,internal) ,
    FUNCTION 3 gbt_oid_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_oid_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_oid_picksplit(internal,internal) ,
    FUNCTION 7 gbt_oid_same(internal,internal,internal);


--
-- Name: gist_text_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_text_ops USING gist;


--
-- Name: gist_text_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_text_ops
    DEFAULT FOR TYPE text USING gist AS
    STORAGE gbtreekey_var ,
    OPERATOR 1 <(text,text) ,
    OPERATOR 2 <=(text,text) ,
    OPERATOR 3 =(text,text) ,
    OPERATOR 4 >=(text,text) ,
    OPERATOR 5 >(text,text) ,
    FUNCTION 1 gbt_text_consistent(internal,text,smallint,oid,internal) ,
    FUNCTION 2 gbt_text_union(bytea,internal) ,
    FUNCTION 3 gbt_text_compress(internal) ,
    FUNCTION 4 gbt_var_decompress(internal) ,
    FUNCTION 5 gbt_text_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_text_picksplit(internal,internal) ,
    FUNCTION 7 gbt_text_same(internal,internal,internal);


--
-- Name: gist_time_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_time_ops USING gist;


--
-- Name: gist_time_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_time_ops
    DEFAULT FOR TYPE time without time zone USING gist AS
    STORAGE gbtreekey16 ,
    OPERATOR 1 <(time without time zone,time without time zone) ,
    OPERATOR 2 <=(time without time zone,time without time zone) ,
    OPERATOR 3 =(time without time zone,time without time zone) ,
    OPERATOR 4 >=(time without time zone,time without time zone) ,
    OPERATOR 5 >(time without time zone,time without time zone) ,
    FUNCTION 1 gbt_time_consistent(internal,time without time zone,smallint,oid,internal) ,
    FUNCTION 2 gbt_time_union(bytea,internal) ,
    FUNCTION 3 gbt_time_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_time_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_time_picksplit(internal,internal) ,
    FUNCTION 7 gbt_time_same(internal,internal,internal);


--
-- Name: gist_timestamp_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_timestamp_ops USING gist;


--
-- Name: gist_timestamp_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_timestamp_ops
    DEFAULT FOR TYPE timestamp without time zone USING gist AS
    STORAGE gbtreekey16 ,
    OPERATOR 1 <(timestamp without time zone,timestamp without time zone) ,
    OPERATOR 2 <=(timestamp without time zone,timestamp without time zone) ,
    OPERATOR 3 =(timestamp without time zone,timestamp without time zone) ,
    OPERATOR 4 >=(timestamp without time zone,timestamp without time zone) ,
    OPERATOR 5 >(timestamp without time zone,timestamp without time zone) ,
    FUNCTION 1 gbt_ts_consistent(internal,timestamp without time zone,smallint,oid,internal) ,
    FUNCTION 2 gbt_ts_union(bytea,internal) ,
    FUNCTION 3 gbt_ts_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_ts_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_ts_picksplit(internal,internal) ,
    FUNCTION 7 gbt_ts_same(internal,internal,internal);


--
-- Name: gist_timestamptz_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_timestamptz_ops USING gist;


--
-- Name: gist_timestamptz_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_timestamptz_ops
    DEFAULT FOR TYPE timestamp with time zone USING gist AS
    STORAGE gbtreekey16 ,
    OPERATOR 1 <(timestamp with time zone,timestamp with time zone) ,
    OPERATOR 2 <=(timestamp with time zone,timestamp with time zone) ,
    OPERATOR 3 =(timestamp with time zone,timestamp with time zone) ,
    OPERATOR 4 >=(timestamp with time zone,timestamp with time zone) ,
    OPERATOR 5 >(timestamp with time zone,timestamp with time zone) ,
    FUNCTION 1 gbt_tstz_consistent(internal,timestamp with time zone,smallint,oid,internal) ,
    FUNCTION 2 gbt_ts_union(bytea,internal) ,
    FUNCTION 3 gbt_tstz_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_ts_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_ts_picksplit(internal,internal) ,
    FUNCTION 7 gbt_ts_same(internal,internal,internal);


--
-- Name: gist_timetz_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_timetz_ops USING gist;


--
-- Name: gist_timetz_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_timetz_ops
    DEFAULT FOR TYPE time with time zone USING gist AS
    STORAGE gbtreekey16 ,
    OPERATOR 1 <(time with time zone,time with time zone) ,
    OPERATOR 2 <=(time with time zone,time with time zone) ,
    OPERATOR 3 =(time with time zone,time with time zone) ,
    OPERATOR 4 >=(time with time zone,time with time zone) ,
    OPERATOR 5 >(time with time zone,time with time zone) ,
    FUNCTION 1 gbt_timetz_consistent(internal,time with time zone,smallint,oid,internal) ,
    FUNCTION 2 gbt_time_union(bytea,internal) ,
    FUNCTION 3 gbt_timetz_compress(internal) ,
    FUNCTION 4 gbt_decompress(internal) ,
    FUNCTION 5 gbt_time_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_time_picksplit(internal,internal) ,
    FUNCTION 7 gbt_time_same(internal,internal,internal);


--
-- Name: gist_vbit_ops; Type: OPERATOR FAMILY; Schema: public; Owner: -
--

CREATE OPERATOR FAMILY gist_vbit_ops USING gist;


--
-- Name: gist_vbit_ops; Type: OPERATOR CLASS; Schema: public; Owner: -
--

CREATE OPERATOR CLASS gist_vbit_ops
    DEFAULT FOR TYPE bit varying USING gist AS
    STORAGE gbtreekey_var ,
    OPERATOR 1 <(bit varying,bit varying) ,
    OPERATOR 2 <=(bit varying,bit varying) ,
    OPERATOR 3 =(bit varying,bit varying) ,
    OPERATOR 4 >=(bit varying,bit varying) ,
    OPERATOR 5 >(bit varying,bit varying) ,
    FUNCTION 1 gbt_bit_consistent(internal,bit,smallint,oid,internal) ,
    FUNCTION 2 gbt_bit_union(bytea,internal) ,
    FUNCTION 3 gbt_bit_compress(internal) ,
    FUNCTION 4 gbt_var_decompress(internal) ,
    FUNCTION 5 gbt_bit_penalty(internal,internal,internal) ,
    FUNCTION 6 gbt_bit_picksplit(internal,internal) ,
    FUNCTION 7 gbt_bit_same(internal,internal,internal);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: acls; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE acls (
    id integer NOT NULL,
    address inet,
    k character varying(255) NOT NULL,
    v character varying(255),
    domain character varying(255)
);


--
-- Name: acls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE acls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: acls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE acls_id_seq OWNED BY acls.id;


--
-- Name: changeset_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE changeset_tags (
    changeset_id bigint NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: changesets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE changesets (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    min_lat integer,
    max_lat integer,
    min_lon integer,
    max_lon integer,
    closed_at timestamp without time zone NOT NULL,
    num_changes integer DEFAULT 0 NOT NULL
);


--
-- Name: changesets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE changesets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: changesets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE changesets_id_seq OWNED BY changesets.id;


--
-- Name: client_applications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE client_applications (
    id integer NOT NULL,
    name character varying(255),
    url character varying(255),
    support_url character varying(255),
    callback_url character varying(255),
    key character varying(50),
    secret character varying(50),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    allow_read_prefs boolean DEFAULT false NOT NULL,
    allow_write_prefs boolean DEFAULT false NOT NULL,
    allow_write_diary boolean DEFAULT false NOT NULL,
    allow_write_api boolean DEFAULT false NOT NULL,
    allow_read_gpx boolean DEFAULT false NOT NULL,
    allow_write_gpx boolean DEFAULT false NOT NULL
);


--
-- Name: client_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE client_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE client_applications_id_seq OWNED BY client_applications.id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE countries (
    id integer NOT NULL,
    code character varying(2) NOT NULL,
    min_lat double precision NOT NULL,
    max_lat double precision NOT NULL,
    min_lon double precision NOT NULL,
    max_lon double precision NOT NULL
);


--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE countries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE countries_id_seq OWNED BY countries.id;


--
-- Name: current_node_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE current_node_tags (
    node_id bigint NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: current_nodes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE current_nodes (
    id bigint NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    changeset_id bigint NOT NULL,
    visible boolean NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    tile bigint NOT NULL,
    version bigint NOT NULL
);


--
-- Name: current_nodes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE current_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: current_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE current_nodes_id_seq OWNED BY current_nodes.id;


--
-- Name: current_relation_members; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE current_relation_members (
    relation_id bigint NOT NULL,
    member_type nwr_enum NOT NULL,
    member_id bigint NOT NULL,
    member_role character varying(255) NOT NULL,
    sequence_id integer DEFAULT 0 NOT NULL
);


--
-- Name: current_relation_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE current_relation_tags (
    relation_id bigint NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: current_relations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE current_relations (
    id bigint NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    visible boolean NOT NULL,
    version bigint NOT NULL
);


--
-- Name: current_relations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE current_relations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: current_relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE current_relations_id_seq OWNED BY current_relations.id;


--
-- Name: current_way_nodes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE current_way_nodes (
    way_id bigint NOT NULL,
    node_id bigint NOT NULL,
    sequence_id bigint NOT NULL
);


--
-- Name: current_way_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE current_way_tags (
    way_id bigint NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: current_ways; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE current_ways (
    id bigint NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    visible boolean NOT NULL,
    version bigint NOT NULL
);


--
-- Name: current_ways_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE current_ways_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: current_ways_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE current_ways_id_seq OWNED BY current_ways.id;


--
-- Name: diary_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE diary_comments (
    id bigint NOT NULL,
    diary_entry_id bigint NOT NULL,
    user_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    visible boolean DEFAULT true NOT NULL
);


--
-- Name: diary_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE diary_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: diary_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE diary_comments_id_seq OWNED BY diary_comments.id;


--
-- Name: diary_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE diary_entries (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    title character varying(255) NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    latitude double precision,
    longitude double precision,
    language_code character varying(255) DEFAULT 'en'::character varying NOT NULL,
    visible boolean DEFAULT true NOT NULL
);


--
-- Name: diary_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE diary_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: diary_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE diary_entries_id_seq OWNED BY diary_entries.id;


--
-- Name: friends; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE friends (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    friend_user_id bigint NOT NULL
);


--
-- Name: friends_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE friends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: friends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE friends_id_seq OWNED BY friends.id;


--
-- Name: gps_points; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gps_points (
    altitude double precision,
    trackid integer NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    gpx_id bigint NOT NULL,
    "timestamp" timestamp without time zone,
    tile bigint
);


--
-- Name: gpx_file_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gpx_file_tags (
    gpx_id bigint DEFAULT 0 NOT NULL,
    tag character varying(255) NOT NULL,
    id bigint NOT NULL
);


--
-- Name: gpx_file_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gpx_file_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gpx_file_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gpx_file_tags_id_seq OWNED BY gpx_file_tags.id;


--
-- Name: gpx_files; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gpx_files (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    name character varying(255) DEFAULT ''::character varying NOT NULL,
    size bigint,
    latitude double precision,
    longitude double precision,
    "timestamp" timestamp without time zone NOT NULL,
    description character varying(255) DEFAULT ''::character varying NOT NULL,
    inserted boolean NOT NULL,
    visibility gpx_visibility_enum DEFAULT 'public'::gpx_visibility_enum NOT NULL
);


--
-- Name: gpx_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gpx_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gpx_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gpx_files_id_seq OWNED BY gpx_files.id;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE languages (
    code character varying(255) NOT NULL,
    english_name character varying(255) NOT NULL,
    native_name character varying(255)
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE messages (
    id bigint NOT NULL,
    from_user_id bigint NOT NULL,
    title character varying(255) NOT NULL,
    body text NOT NULL,
    sent_on timestamp without time zone NOT NULL,
    message_read boolean DEFAULT false NOT NULL,
    to_user_id bigint NOT NULL,
    to_user_visible boolean DEFAULT true NOT NULL,
    from_user_visible boolean DEFAULT true NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE messages_id_seq OWNED BY messages.id;


--
-- Name: node_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE node_tags (
    node_id bigint NOT NULL,
    version bigint NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: nodes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE nodes (
    node_id bigint NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    changeset_id bigint NOT NULL,
    visible boolean NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    tile bigint NOT NULL,
    version bigint NOT NULL
);


--
-- Name: oauth_nonces; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oauth_nonces (
    id integer NOT NULL,
    nonce character varying(255),
    "timestamp" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: oauth_nonces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_nonces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_nonces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_nonces_id_seq OWNED BY oauth_nonces.id;


--
-- Name: oauth_tokens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oauth_tokens (
    id integer NOT NULL,
    user_id integer,
    type character varying(20),
    client_application_id integer,
    token character varying(50),
    secret character varying(50),
    authorized_at timestamp without time zone,
    invalidated_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    allow_read_prefs boolean DEFAULT false NOT NULL,
    allow_write_prefs boolean DEFAULT false NOT NULL,
    allow_write_diary boolean DEFAULT false NOT NULL,
    allow_write_api boolean DEFAULT false NOT NULL,
    allow_read_gpx boolean DEFAULT false NOT NULL,
    allow_write_gpx boolean DEFAULT false NOT NULL,
    callback_url character varying(255),
    verifier character varying(20),
    scope character varying(255),
    valid_to timestamp without time zone
);


--
-- Name: oauth_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_tokens_id_seq OWNED BY oauth_tokens.id;


--
-- Name: relation_members; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE relation_members (
    relation_id bigint DEFAULT 0 NOT NULL,
    member_type nwr_enum NOT NULL,
    member_id bigint NOT NULL,
    member_role character varying(255) NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    sequence_id integer DEFAULT 0 NOT NULL
);


--
-- Name: relation_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE relation_tags (
    relation_id bigint DEFAULT 0 NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL,
    version bigint NOT NULL
);


--
-- Name: relations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE relations (
    relation_id bigint DEFAULT 0 NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    version bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id character varying(255),
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: user_blocks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_blocks (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    reason text NOT NULL,
    ends_at timestamp without time zone NOT NULL,
    needs_view boolean DEFAULT false NOT NULL,
    revoker_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_blocks_id_seq OWNED BY user_blocks.id;


--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_preferences (
    user_id bigint NOT NULL,
    k character varying(255) NOT NULL,
    v character varying(255) NOT NULL
);


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_roles (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    role user_role_enum NOT NULL,
    granter_id bigint NOT NULL
);


--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_roles_id_seq OWNED BY user_roles.id;


--
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying(255) NOT NULL,
    expiry timestamp without time zone NOT NULL,
    referer text
);


--
-- Name: user_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_tokens_id_seq OWNED BY user_tokens.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    email character varying(255) NOT NULL,
    id bigint NOT NULL,
    pass_crypt character varying(255) NOT NULL,
    creation_time timestamp without time zone NOT NULL,
    display_name character varying(255) DEFAULT ''::character varying NOT NULL,
    data_public boolean DEFAULT false NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    home_lat double precision,
    home_lon double precision,
    home_zoom smallint DEFAULT 3,
    nearby integer DEFAULT 50,
    pass_salt character varying(255),
    image_file_name text,
    email_valid boolean DEFAULT false NOT NULL,
    new_email character varying(255),
    creation_ip character varying(255),
    languages character varying(255),
    status user_status_enum DEFAULT 'pending'::user_status_enum NOT NULL,
    terms_agreed timestamp without time zone,
    consider_pd boolean DEFAULT false NOT NULL,
    preferred_editor character varying(255),
    terms_seen boolean DEFAULT false NOT NULL,
    openid_url character varying(255),
    image_fingerprint character varying(255)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: way_nodes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE way_nodes (
    way_id bigint NOT NULL,
    node_id bigint NOT NULL,
    version bigint NOT NULL,
    sequence_id bigint NOT NULL
);


--
-- Name: way_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE way_tags (
    way_id bigint DEFAULT 0 NOT NULL,
    k character varying(255) NOT NULL,
    v character varying(255) NOT NULL,
    version bigint NOT NULL
);


--
-- Name: ways; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ways (
    way_id bigint DEFAULT 0 NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    version bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL
);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE acls ALTER COLUMN id SET DEFAULT nextval('acls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE changesets ALTER COLUMN id SET DEFAULT nextval('changesets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE client_applications ALTER COLUMN id SET DEFAULT nextval('client_applications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE countries ALTER COLUMN id SET DEFAULT nextval('countries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE current_nodes ALTER COLUMN id SET DEFAULT nextval('current_nodes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE current_relations ALTER COLUMN id SET DEFAULT nextval('current_relations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE current_ways ALTER COLUMN id SET DEFAULT nextval('current_ways_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE diary_comments ALTER COLUMN id SET DEFAULT nextval('diary_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE diary_entries ALTER COLUMN id SET DEFAULT nextval('diary_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE friends ALTER COLUMN id SET DEFAULT nextval('friends_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE gpx_file_tags ALTER COLUMN id SET DEFAULT nextval('gpx_file_tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE gpx_files ALTER COLUMN id SET DEFAULT nextval('gpx_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE messages ALTER COLUMN id SET DEFAULT nextval('messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE oauth_nonces ALTER COLUMN id SET DEFAULT nextval('oauth_nonces_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE oauth_tokens ALTER COLUMN id SET DEFAULT nextval('oauth_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_blocks ALTER COLUMN id SET DEFAULT nextval('user_blocks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_roles ALTER COLUMN id SET DEFAULT nextval('user_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE user_tokens ALTER COLUMN id SET DEFAULT nextval('user_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: acls_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY acls
    ADD CONSTRAINT acls_pkey PRIMARY KEY (id);


--
-- Name: changesets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_pkey PRIMARY KEY (id);


--
-- Name: client_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY client_applications
    ADD CONSTRAINT client_applications_pkey PRIMARY KEY (id);


--
-- Name: countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: current_node_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY current_node_tags
    ADD CONSTRAINT current_node_tags_pkey PRIMARY KEY (node_id, k);


--
-- Name: current_nodes_pkey1; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY current_nodes
    ADD CONSTRAINT current_nodes_pkey1 PRIMARY KEY (id);


--
-- Name: current_relation_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY current_relation_members
    ADD CONSTRAINT current_relation_members_pkey PRIMARY KEY (relation_id, member_type, member_id, member_role, sequence_id);


--
-- Name: current_relation_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY current_relation_tags
    ADD CONSTRAINT current_relation_tags_pkey PRIMARY KEY (relation_id, k);


--
-- Name: current_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY current_relations
    ADD CONSTRAINT current_relations_pkey PRIMARY KEY (id);


--
-- Name: current_way_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY current_way_nodes
    ADD CONSTRAINT current_way_nodes_pkey PRIMARY KEY (way_id, sequence_id);


--
-- Name: current_way_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY current_way_tags
    ADD CONSTRAINT current_way_tags_pkey PRIMARY KEY (way_id, k);


--
-- Name: current_ways_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY current_ways
    ADD CONSTRAINT current_ways_pkey PRIMARY KEY (id);


--
-- Name: diary_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY diary_comments
    ADD CONSTRAINT diary_comments_pkey PRIMARY KEY (id);


--
-- Name: diary_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY diary_entries
    ADD CONSTRAINT diary_entries_pkey PRIMARY KEY (id);


--
-- Name: friends_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY friends
    ADD CONSTRAINT friends_pkey PRIMARY KEY (id);


--
-- Name: gpx_file_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gpx_file_tags
    ADD CONSTRAINT gpx_file_tags_pkey PRIMARY KEY (id);


--
-- Name: gpx_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gpx_files
    ADD CONSTRAINT gpx_files_pkey PRIMARY KEY (id);


--
-- Name: languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (code);


--
-- Name: messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: node_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY node_tags
    ADD CONSTRAINT node_tags_pkey PRIMARY KEY (node_id, version, k);


--
-- Name: nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY nodes
    ADD CONSTRAINT nodes_pkey PRIMARY KEY (node_id, version);


--
-- Name: oauth_nonces_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_nonces
    ADD CONSTRAINT oauth_nonces_pkey PRIMARY KEY (id);


--
-- Name: oauth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_tokens
    ADD CONSTRAINT oauth_tokens_pkey PRIMARY KEY (id);


--
-- Name: relation_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY relation_members
    ADD CONSTRAINT relation_members_pkey PRIMARY KEY (relation_id, version, member_type, member_id, member_role, sequence_id);


--
-- Name: relation_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY relation_tags
    ADD CONSTRAINT relation_tags_pkey PRIMARY KEY (relation_id, version, k);


--
-- Name: relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY relations
    ADD CONSTRAINT relations_pkey PRIMARY KEY (relation_id, version);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: user_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_blocks
    ADD CONSTRAINT user_blocks_pkey PRIMARY KEY (id);


--
-- Name: user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (user_id, k);


--
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: way_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY way_nodes
    ADD CONSTRAINT way_nodes_pkey PRIMARY KEY (way_id, version, sequence_id);


--
-- Name: way_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY way_tags
    ADD CONSTRAINT way_tags_pkey PRIMARY KEY (way_id, version, k);


--
-- Name: ways_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ways
    ADD CONSTRAINT ways_pkey PRIMARY KEY (way_id, version);


--
-- Name: acls_k_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX acls_k_idx ON acls USING btree (k);


--
-- Name: changeset_tags_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX changeset_tags_id_idx ON changeset_tags USING btree (changeset_id);


--
-- Name: changesets_bbox_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX changesets_bbox_idx ON changesets USING gist (min_lat, max_lat, min_lon, max_lon);


--
-- Name: changesets_closed_at_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX changesets_closed_at_idx ON changesets USING btree (closed_at);


--
-- Name: changesets_created_at_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX changesets_created_at_idx ON changesets USING btree (created_at);


--
-- Name: changesets_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX changesets_user_id_created_at_idx ON changesets USING btree (user_id, created_at);


--
-- Name: changesets_user_id_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX changesets_user_id_id_idx ON changesets USING btree (user_id, id);


--
-- Name: countries_code_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX countries_code_idx ON countries USING btree (code);


--
-- Name: current_nodes_tile_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX current_nodes_tile_idx ON current_nodes USING btree (tile);


--
-- Name: current_nodes_timestamp_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX current_nodes_timestamp_idx ON current_nodes USING btree ("timestamp");


--
-- Name: current_relation_members_member_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX current_relation_members_member_idx ON current_relation_members USING btree (member_type, member_id);


--
-- Name: current_relations_timestamp_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX current_relations_timestamp_idx ON current_relations USING btree ("timestamp");


--
-- Name: current_way_nodes_node_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX current_way_nodes_node_idx ON current_way_nodes USING btree (node_id);


--
-- Name: current_ways_timestamp_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX current_ways_timestamp_idx ON current_ways USING btree ("timestamp");


--
-- Name: diary_comment_user_id_created_at_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX diary_comment_user_id_created_at_index ON diary_comments USING btree (user_id, created_at);


--
-- Name: diary_comments_entry_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX diary_comments_entry_id_idx ON diary_comments USING btree (diary_entry_id, id);


--
-- Name: diary_entry_created_at_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX diary_entry_created_at_index ON diary_entries USING btree (created_at);


--
-- Name: diary_entry_language_code_created_at_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX diary_entry_language_code_created_at_index ON diary_entries USING btree (language_code, created_at);


--
-- Name: diary_entry_user_id_created_at_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX diary_entry_user_id_created_at_index ON diary_entries USING btree (user_id, created_at);


--
-- Name: friends_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX friends_user_id_idx ON friends USING btree (user_id);


--
-- Name: gpx_file_tags_gpxid_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX gpx_file_tags_gpxid_idx ON gpx_file_tags USING btree (gpx_id);


--
-- Name: gpx_file_tags_tag_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX gpx_file_tags_tag_idx ON gpx_file_tags USING btree (tag);


--
-- Name: gpx_files_timestamp_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX gpx_files_timestamp_idx ON gpx_files USING btree ("timestamp");


--
-- Name: gpx_files_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX gpx_files_user_id_idx ON gpx_files USING btree (user_id);


--
-- Name: gpx_files_visible_visibility_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX gpx_files_visible_visibility_idx ON gpx_files USING btree (visible, visibility);


--
-- Name: index_client_applications_on_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_client_applications_on_key ON client_applications USING btree (key);


--
-- Name: index_oauth_nonces_on_nonce_and_timestamp; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_oauth_nonces_on_nonce_and_timestamp ON oauth_nonces USING btree (nonce, "timestamp");


--
-- Name: index_oauth_tokens_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_oauth_tokens_on_token ON oauth_tokens USING btree (token);


--
-- Name: index_user_blocks_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_user_blocks_on_user_id ON user_blocks USING btree (user_id);


--
-- Name: messages_from_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_from_user_id_idx ON messages USING btree (from_user_id);


--
-- Name: messages_to_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX messages_to_user_id_idx ON messages USING btree (to_user_id);


--
-- Name: nodes_changeset_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX nodes_changeset_id_idx ON nodes USING btree (changeset_id);


--
-- Name: nodes_tile_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX nodes_tile_idx ON nodes USING btree (tile);


--
-- Name: nodes_timestamp_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX nodes_timestamp_idx ON nodes USING btree ("timestamp");


--
-- Name: points_gpxid_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX points_gpxid_idx ON gps_points USING btree (gpx_id);


--
-- Name: points_tile_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX points_tile_idx ON gps_points USING btree (tile);


--
-- Name: relation_members_member_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX relation_members_member_idx ON relation_members USING btree (member_type, member_id);


--
-- Name: relations_changeset_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX relations_changeset_id_idx ON relations USING btree (changeset_id);


--
-- Name: relations_timestamp_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX relations_timestamp_idx ON relations USING btree ("timestamp");


--
-- Name: sessions_session_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX sessions_session_id_idx ON sessions USING btree (session_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX user_id_idx ON friends USING btree (friend_user_id);


--
-- Name: user_openid_url_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX user_openid_url_idx ON users USING btree (openid_url);


--
-- Name: user_roles_id_role_unique; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX user_roles_id_role_unique ON user_roles USING btree (user_id, role);


--
-- Name: user_tokens_token_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX user_tokens_token_idx ON user_tokens USING btree (token);


--
-- Name: user_tokens_user_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX user_tokens_user_id_idx ON user_tokens USING btree (user_id);


--
-- Name: users_display_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_display_name_idx ON users USING btree (display_name);


--
-- Name: users_display_name_lower_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_display_name_lower_idx ON users USING btree (lower((display_name)::text));


--
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_email_idx ON users USING btree (email);


--
-- Name: users_email_lower_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_email_lower_idx ON users USING btree (lower((email)::text));


--
-- Name: way_nodes_node_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX way_nodes_node_idx ON way_nodes USING btree (node_id);


--
-- Name: ways_changeset_id_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ways_changeset_id_idx ON ways USING btree (changeset_id);


--
-- Name: ways_timestamp_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ways_timestamp_idx ON ways USING btree ("timestamp");


--
-- Name: changeset_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changeset_tags
    ADD CONSTRAINT changeset_tags_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id);


--
-- Name: changesets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: client_applications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_applications
    ADD CONSTRAINT client_applications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: current_node_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_node_tags
    ADD CONSTRAINT current_node_tags_id_fkey FOREIGN KEY (node_id) REFERENCES current_nodes(id);


--
-- Name: current_nodes_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_nodes
    ADD CONSTRAINT current_nodes_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id);


--
-- Name: current_relation_members_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_relation_members
    ADD CONSTRAINT current_relation_members_id_fkey FOREIGN KEY (relation_id) REFERENCES current_relations(id);


--
-- Name: current_relation_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_relation_tags
    ADD CONSTRAINT current_relation_tags_id_fkey FOREIGN KEY (relation_id) REFERENCES current_relations(id);


--
-- Name: current_relations_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_relations
    ADD CONSTRAINT current_relations_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id);


--
-- Name: current_way_nodes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_way_nodes
    ADD CONSTRAINT current_way_nodes_id_fkey FOREIGN KEY (way_id) REFERENCES current_ways(id);


--
-- Name: current_way_nodes_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_way_nodes
    ADD CONSTRAINT current_way_nodes_node_id_fkey FOREIGN KEY (node_id) REFERENCES current_nodes(id);


--
-- Name: current_way_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_way_tags
    ADD CONSTRAINT current_way_tags_id_fkey FOREIGN KEY (way_id) REFERENCES current_ways(id);


--
-- Name: current_ways_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_ways
    ADD CONSTRAINT current_ways_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id);


--
-- Name: diary_comments_diary_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY diary_comments
    ADD CONSTRAINT diary_comments_diary_entry_id_fkey FOREIGN KEY (diary_entry_id) REFERENCES diary_entries(id);


--
-- Name: diary_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY diary_comments
    ADD CONSTRAINT diary_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: diary_entries_language_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY diary_entries
    ADD CONSTRAINT diary_entries_language_code_fkey FOREIGN KEY (language_code) REFERENCES languages(code);


--
-- Name: diary_entries_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY diary_entries
    ADD CONSTRAINT diary_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: friends_friend_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY friends
    ADD CONSTRAINT friends_friend_user_id_fkey FOREIGN KEY (friend_user_id) REFERENCES users(id);


--
-- Name: friends_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY friends
    ADD CONSTRAINT friends_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: gps_points_gpx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gps_points
    ADD CONSTRAINT gps_points_gpx_id_fkey FOREIGN KEY (gpx_id) REFERENCES gpx_files(id);


--
-- Name: gpx_file_tags_gpx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gpx_file_tags
    ADD CONSTRAINT gpx_file_tags_gpx_id_fkey FOREIGN KEY (gpx_id) REFERENCES gpx_files(id);


--
-- Name: gpx_files_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gpx_files
    ADD CONSTRAINT gpx_files_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: messages_from_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_from_user_id_fkey FOREIGN KEY (from_user_id) REFERENCES users(id);


--
-- Name: messages_to_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_to_user_id_fkey FOREIGN KEY (to_user_id) REFERENCES users(id);


--
-- Name: node_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY node_tags
    ADD CONSTRAINT node_tags_id_fkey FOREIGN KEY (node_id, version) REFERENCES nodes(node_id, version);


--
-- Name: nodes_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY nodes
    ADD CONSTRAINT nodes_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id);


--
-- Name: oauth_tokens_client_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_tokens
    ADD CONSTRAINT oauth_tokens_client_application_id_fkey FOREIGN KEY (client_application_id) REFERENCES client_applications(id);


--
-- Name: oauth_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_tokens
    ADD CONSTRAINT oauth_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: relation_members_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY relation_members
    ADD CONSTRAINT relation_members_id_fkey FOREIGN KEY (relation_id, version) REFERENCES relations(relation_id, version);


--
-- Name: relation_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY relation_tags
    ADD CONSTRAINT relation_tags_id_fkey FOREIGN KEY (relation_id, version) REFERENCES relations(relation_id, version);


--
-- Name: relations_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY relations
    ADD CONSTRAINT relations_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id);


--
-- Name: user_blocks_moderator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_blocks
    ADD CONSTRAINT user_blocks_moderator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: user_blocks_revoker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_blocks
    ADD CONSTRAINT user_blocks_revoker_id_fkey FOREIGN KEY (revoker_id) REFERENCES users(id);


--
-- Name: user_blocks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_blocks
    ADD CONSTRAINT user_blocks_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: user_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: user_roles_granter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_granter_id_fkey FOREIGN KEY (granter_id) REFERENCES users(id);


--
-- Name: user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: user_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_tokens
    ADD CONSTRAINT user_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: way_nodes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY way_nodes
    ADD CONSTRAINT way_nodes_id_fkey FOREIGN KEY (way_id, version) REFERENCES ways(way_id, version);


--
-- Name: way_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY way_tags
    ADD CONSTRAINT way_tags_id_fkey FOREIGN KEY (way_id, version) REFERENCES ways(way_id, version);


--
-- Name: ways_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ways
    ADD CONSTRAINT ways_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('14');

INSERT INTO schema_migrations (version) VALUES ('15');

INSERT INTO schema_migrations (version) VALUES ('16');

INSERT INTO schema_migrations (version) VALUES ('17');

INSERT INTO schema_migrations (version) VALUES ('18');

INSERT INTO schema_migrations (version) VALUES ('19');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('20');

INSERT INTO schema_migrations (version) VALUES ('20100513171259');

INSERT INTO schema_migrations (version) VALUES ('20100516124737');

INSERT INTO schema_migrations (version) VALUES ('20100910084426');

INSERT INTO schema_migrations (version) VALUES ('20101114011429');

INSERT INTO schema_migrations (version) VALUES ('20110322001319');

INSERT INTO schema_migrations (version) VALUES ('20110925112722');

INSERT INTO schema_migrations (version) VALUES ('20111116184519');

INSERT INTO schema_migrations (version) VALUES ('20111212183945');

INSERT INTO schema_migrations (version) VALUES ('20120123184321');

INSERT INTO schema_migrations (version) VALUES ('20120208122334');

INSERT INTO schema_migrations (version) VALUES ('20120208194454');

INSERT INTO schema_migrations (version) VALUES ('20120219161649');

INSERT INTO schema_migrations (version) VALUES ('21');

INSERT INTO schema_migrations (version) VALUES ('22');

INSERT INTO schema_migrations (version) VALUES ('23');

INSERT INTO schema_migrations (version) VALUES ('24');

INSERT INTO schema_migrations (version) VALUES ('25');

INSERT INTO schema_migrations (version) VALUES ('26');

INSERT INTO schema_migrations (version) VALUES ('27');

INSERT INTO schema_migrations (version) VALUES ('28');

INSERT INTO schema_migrations (version) VALUES ('29');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('30');

INSERT INTO schema_migrations (version) VALUES ('31');

INSERT INTO schema_migrations (version) VALUES ('32');

INSERT INTO schema_migrations (version) VALUES ('33');

INSERT INTO schema_migrations (version) VALUES ('34');

INSERT INTO schema_migrations (version) VALUES ('35');

INSERT INTO schema_migrations (version) VALUES ('36');

INSERT INTO schema_migrations (version) VALUES ('37');

INSERT INTO schema_migrations (version) VALUES ('38');

INSERT INTO schema_migrations (version) VALUES ('39');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('40');

INSERT INTO schema_migrations (version) VALUES ('41');

INSERT INTO schema_migrations (version) VALUES ('42');

INSERT INTO schema_migrations (version) VALUES ('43');

INSERT INTO schema_migrations (version) VALUES ('44');

INSERT INTO schema_migrations (version) VALUES ('45');

INSERT INTO schema_migrations (version) VALUES ('46');

INSERT INTO schema_migrations (version) VALUES ('47');

INSERT INTO schema_migrations (version) VALUES ('48');

INSERT INTO schema_migrations (version) VALUES ('49');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('50');

INSERT INTO schema_migrations (version) VALUES ('51');

INSERT INTO schema_migrations (version) VALUES ('52');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('9');
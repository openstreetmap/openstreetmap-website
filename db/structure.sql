SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: format_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.format_enum AS ENUM (
    'html',
    'markdown',
    'text'
);


--
-- Name: gpx_visibility_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.gpx_visibility_enum AS ENUM (
    'private',
    'public',
    'trackable',
    'identifiable'
);


--
-- Name: issue_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.issue_status_enum AS ENUM (
    'open',
    'ignored',
    'resolved'
);


--
-- Name: note_event_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.note_event_enum AS ENUM (
    'opened',
    'closed',
    'reopened',
    'commented',
    'hidden'
);


--
-- Name: note_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.note_status_enum AS ENUM (
    'open',
    'closed',
    'hidden'
);


--
-- Name: nwr_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.nwr_enum AS ENUM (
    'Node',
    'Way',
    'Relation'
);


--
-- Name: user_role_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role_enum AS ENUM (
    'administrator',
    'moderator'
);


--
-- Name: user_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_status_enum AS ENUM (
    'pending',
    'active',
    'confirmed',
    'suspended',
    'deleted'
);


--
-- Name: maptile_for_point(bigint, bigint, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.maptile_for_point(scaled_lat bigint, scaled_lon bigint, zoom integer) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
  lat CONSTANT DOUBLE PRECISION := scaled_lat / 10000000.0;
  lon CONSTANT DOUBLE PRECISION := scaled_lon / 10000000.0;
  zscale CONSTANT DOUBLE PRECISION := 2.0 ^ zoom;
  pi CONSTANT DOUBLE PRECISION := 3.141592653589793;
  r_per_d CONSTANT DOUBLE PRECISION := pi / 180.0;
  x int4;
  y int4;
BEGIN
  -- straight port of the C code. see db/functions/maptile.c
  x := floor((lon + 180.0) * zscale / 360.0);
  y := floor((1.0 - ln(tan(lat * r_per_d) + 1.0 / cos(lat * r_per_d)) / pi) * zscale / 2.0);

  RETURN (x << zoom) | y;
END;
$$;


--
-- Name: tile_for_point(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.tile_for_point(scaled_lat integer, scaled_lon integer) RETURNS bigint
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
  x int8; -- quantized x from lon,
  y int8; -- quantized y from lat,
BEGIN
  x := round(((scaled_lon / 10000000.0) + 180.0) * 65535.0 / 360.0);
  y := round(((scaled_lat / 10000000.0) +  90.0) * 65535.0 / 180.0);

  -- these bit-masks are special numbers used in the bit interleaving algorithm.
  -- see https://graphics.stanford.edu/~seander/bithacks.html#InterleaveBMN
  -- for the original algorithm and more details.
  x := (x | (x << 8)) &   16711935; -- 0x00FF00FF
  x := (x | (x << 4)) &  252645135; -- 0x0F0F0F0F
  x := (x | (x << 2)) &  858993459; -- 0x33333333
  x := (x | (x << 1)) & 1431655765; -- 0x55555555

  y := (y | (y << 8)) &   16711935; -- 0x00FF00FF
  y := (y | (y << 4)) &  252645135; -- 0x0F0F0F0F
  y := (y | (y << 2)) &  858993459; -- 0x33333333
  y := (y | (y << 1)) & 1431655765; -- 0x55555555

  RETURN (x << 1) | y;
END;
$$;


--
-- Name: xid_to_int4(xid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.xid_to_int4(t xid) RETURNS integer
    LANGUAGE plpgsql STRICT
    AS $$
DECLARE
  tl bigint;
  ti int;
BEGIN
  tl := t;

  IF tl >= 2147483648 THEN
    tl := tl - 4294967296;
  END IF;

  ti := tl;

  RETURN ti;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: acls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.acls (
    id bigint NOT NULL,
    address inet,
    k character varying NOT NULL,
    v character varying,
    domain character varying,
    mx character varying
);


--
-- Name: acls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.acls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: acls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.acls_id_seq OWNED BY public.acls.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: changeset_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.changeset_comments (
    id integer NOT NULL,
    changeset_id bigint NOT NULL,
    author_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    visible boolean NOT NULL
);


--
-- Name: changeset_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.changeset_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: changeset_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.changeset_comments_id_seq OWNED BY public.changeset_comments.id;


--
-- Name: changeset_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.changeset_tags (
    changeset_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: changesets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.changesets (
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

CREATE SEQUENCE public.changesets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: changesets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.changesets_id_seq OWNED BY public.changesets.id;


--
-- Name: changesets_subscribers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.changesets_subscribers (
    subscriber_id bigint NOT NULL,
    changeset_id bigint NOT NULL
);


--
-- Name: client_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_applications (
    id integer NOT NULL,
    name character varying,
    url character varying,
    support_url character varying,
    callback_url character varying,
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
    allow_write_gpx boolean DEFAULT false NOT NULL,
    allow_write_notes boolean DEFAULT false NOT NULL
);


--
-- Name: client_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_applications_id_seq OWNED BY public.client_applications.id;


--
-- Name: current_node_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.current_node_tags (
    node_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: current_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.current_nodes (
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

CREATE SEQUENCE public.current_nodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: current_nodes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.current_nodes_id_seq OWNED BY public.current_nodes.id;


--
-- Name: current_relation_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.current_relation_members (
    relation_id bigint NOT NULL,
    member_type public.nwr_enum NOT NULL,
    member_id bigint NOT NULL,
    member_role character varying NOT NULL,
    sequence_id integer DEFAULT 0 NOT NULL
);


--
-- Name: current_relation_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.current_relation_tags (
    relation_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: current_relations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.current_relations (
    id bigint NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    visible boolean NOT NULL,
    version bigint NOT NULL
);


--
-- Name: current_relations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.current_relations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: current_relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.current_relations_id_seq OWNED BY public.current_relations.id;


--
-- Name: current_way_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.current_way_nodes (
    way_id bigint NOT NULL,
    node_id bigint NOT NULL,
    sequence_id bigint NOT NULL
);


--
-- Name: current_way_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.current_way_tags (
    way_id bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: current_ways; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.current_ways (
    id bigint NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    visible boolean NOT NULL,
    version bigint NOT NULL
);


--
-- Name: current_ways_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.current_ways_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: current_ways_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.current_ways_id_seq OWNED BY public.current_ways.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: diary_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.diary_comments (
    id bigint NOT NULL,
    diary_entry_id bigint NOT NULL,
    user_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    body_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL
);


--
-- Name: diary_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.diary_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: diary_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.diary_comments_id_seq OWNED BY public.diary_comments.id;


--
-- Name: diary_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.diary_entries (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    title character varying NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    latitude double precision,
    longitude double precision,
    language_code character varying DEFAULT 'en'::character varying NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    body_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL
);


--
-- Name: diary_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.diary_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: diary_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.diary_entries_id_seq OWNED BY public.diary_entries.id;


--
-- Name: diary_entry_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.diary_entry_subscriptions (
    user_id bigint NOT NULL,
    diary_entry_id bigint NOT NULL
);


--
-- Name: friends; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.friends (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    friend_user_id bigint NOT NULL
);


--
-- Name: friends_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.friends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: friends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.friends_id_seq OWNED BY public.friends.id;


--
-- Name: gps_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gps_points (
    altitude double precision,
    trackid integer NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    gpx_id bigint NOT NULL,
    "timestamp" timestamp without time zone,
    tile bigint
);


--
-- Name: gpx_file_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gpx_file_tags (
    gpx_id bigint DEFAULT 0 NOT NULL,
    tag character varying NOT NULL,
    id bigint NOT NULL
);


--
-- Name: gpx_file_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gpx_file_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gpx_file_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gpx_file_tags_id_seq OWNED BY public.gpx_file_tags.id;


--
-- Name: gpx_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gpx_files (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    size bigint,
    latitude double precision,
    longitude double precision,
    "timestamp" timestamp without time zone NOT NULL,
    description character varying DEFAULT ''::character varying NOT NULL,
    inserted boolean NOT NULL,
    visibility public.gpx_visibility_enum DEFAULT 'public'::public.gpx_visibility_enum NOT NULL
);


--
-- Name: gpx_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gpx_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gpx_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gpx_files_id_seq OWNED BY public.gpx_files.id;


--
-- Name: issue_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issue_comments (
    id integer NOT NULL,
    issue_id integer NOT NULL,
    user_id integer NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: issue_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issue_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issue_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issue_comments_id_seq OWNED BY public.issue_comments.id;


--
-- Name: issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issues (
    id integer NOT NULL,
    reportable_type character varying NOT NULL,
    reportable_id integer NOT NULL,
    reported_user_id integer,
    status public.issue_status_enum DEFAULT 'open'::public.issue_status_enum NOT NULL,
    assigned_role public.user_role_enum NOT NULL,
    resolved_at timestamp without time zone,
    resolved_by integer,
    updated_by integer,
    reports_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: issues_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issues_id_seq OWNED BY public.issues.id;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.languages (
    code character varying NOT NULL,
    english_name character varying NOT NULL,
    native_name character varying
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    from_user_id bigint NOT NULL,
    title character varying NOT NULL,
    body text NOT NULL,
    sent_on timestamp without time zone NOT NULL,
    message_read boolean DEFAULT false NOT NULL,
    to_user_id bigint NOT NULL,
    to_user_visible boolean DEFAULT true NOT NULL,
    from_user_visible boolean DEFAULT true NOT NULL,
    body_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: node_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.node_tags (
    node_id bigint NOT NULL,
    version bigint NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nodes (
    node_id bigint NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    changeset_id bigint NOT NULL,
    visible boolean NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    tile bigint NOT NULL,
    version bigint NOT NULL,
    redaction_id integer
);


--
-- Name: note_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.note_comments (
    id bigint NOT NULL,
    note_id bigint NOT NULL,
    visible boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    author_ip inet,
    author_id bigint,
    body text,
    event public.note_event_enum
);


--
-- Name: note_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.note_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: note_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.note_comments_id_seq OWNED BY public.note_comments.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    id bigint NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    tile bigint NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    status public.note_status_enum NOT NULL,
    closed_at timestamp without time zone
);


--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: oauth_nonces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_nonces (
    id integer NOT NULL,
    nonce character varying,
    "timestamp" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: oauth_nonces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_nonces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_nonces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_nonces_id_seq OWNED BY public.oauth_nonces.id;


--
-- Name: oauth_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_tokens (
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
    callback_url character varying,
    verifier character varying(20),
    scope character varying,
    valid_to timestamp without time zone,
    allow_write_notes boolean DEFAULT false NOT NULL
);


--
-- Name: oauth_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_tokens_id_seq OWNED BY public.oauth_tokens.id;


--
-- Name: redactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.redactions (
    id integer NOT NULL,
    title character varying,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id bigint NOT NULL,
    description_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL
);


--
-- Name: redactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.redactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.redactions_id_seq OWNED BY public.redactions.id;


--
-- Name: relation_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relation_members (
    relation_id bigint DEFAULT 0 NOT NULL,
    member_type public.nwr_enum NOT NULL,
    member_id bigint NOT NULL,
    member_role character varying NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    sequence_id integer DEFAULT 0 NOT NULL
);


--
-- Name: relation_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relation_tags (
    relation_id bigint DEFAULT 0 NOT NULL,
    k character varying DEFAULT ''::character varying NOT NULL,
    v character varying DEFAULT ''::character varying NOT NULL,
    version bigint NOT NULL
);


--
-- Name: relations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relations (
    relation_id bigint DEFAULT 0 NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    version bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    redaction_id integer
);


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    id integer NOT NULL,
    issue_id integer NOT NULL,
    user_id integer NOT NULL,
    details text NOT NULL,
    category character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reports_id_seq OWNED BY public.reports.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: user_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_blocks (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    reason text NOT NULL,
    ends_at timestamp without time zone NOT NULL,
    needs_view boolean DEFAULT false NOT NULL,
    revoker_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    reason_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL
);


--
-- Name: user_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_blocks_id_seq OWNED BY public.user_blocks.id;


--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_preferences (
    user_id bigint NOT NULL,
    k character varying NOT NULL,
    v character varying NOT NULL
);


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id integer NOT NULL,
    user_id bigint NOT NULL,
    role public.user_role_enum NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    granter_id bigint NOT NULL
);


--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying NOT NULL,
    expiry timestamp without time zone NOT NULL,
    referer text
);


--
-- Name: user_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_tokens_id_seq OWNED BY public.user_tokens.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    email character varying NOT NULL,
    id bigint NOT NULL,
    pass_crypt character varying NOT NULL,
    creation_time timestamp without time zone NOT NULL,
    display_name character varying DEFAULT ''::character varying NOT NULL,
    data_public boolean DEFAULT false NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    home_lat double precision,
    home_lon double precision,
    home_zoom smallint DEFAULT 3,
    pass_salt character varying,
    email_valid boolean DEFAULT false NOT NULL,
    new_email character varying,
    creation_ip character varying,
    languages character varying,
    status public.user_status_enum DEFAULT 'pending'::public.user_status_enum NOT NULL,
    terms_agreed timestamp without time zone,
    consider_pd boolean DEFAULT false NOT NULL,
    auth_uid character varying,
    preferred_editor character varying,
    terms_seen boolean DEFAULT false NOT NULL,
    description_format public.format_enum DEFAULT 'markdown'::public.format_enum NOT NULL,
    changesets_count integer DEFAULT 0 NOT NULL,
    traces_count integer DEFAULT 0 NOT NULL,
    diary_entries_count integer DEFAULT 0 NOT NULL,
    image_use_gravatar boolean DEFAULT false NOT NULL,
    auth_provider character varying,
    home_tile bigint,
    tou_agreed timestamp without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: way_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.way_nodes (
    way_id bigint NOT NULL,
    node_id bigint NOT NULL,
    version bigint NOT NULL,
    sequence_id bigint NOT NULL
);


--
-- Name: way_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.way_tags (
    way_id bigint DEFAULT 0 NOT NULL,
    k character varying NOT NULL,
    v character varying NOT NULL,
    version bigint NOT NULL
);


--
-- Name: ways; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ways (
    way_id bigint DEFAULT 0 NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    version bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    redaction_id integer
);


--
-- Name: acls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acls ALTER COLUMN id SET DEFAULT nextval('public.acls_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: changeset_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.changeset_comments ALTER COLUMN id SET DEFAULT nextval('public.changeset_comments_id_seq'::regclass);


--
-- Name: changesets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.changesets ALTER COLUMN id SET DEFAULT nextval('public.changesets_id_seq'::regclass);


--
-- Name: client_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_applications ALTER COLUMN id SET DEFAULT nextval('public.client_applications_id_seq'::regclass);


--
-- Name: current_nodes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_nodes ALTER COLUMN id SET DEFAULT nextval('public.current_nodes_id_seq'::regclass);


--
-- Name: current_relations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_relations ALTER COLUMN id SET DEFAULT nextval('public.current_relations_id_seq'::regclass);


--
-- Name: current_ways id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_ways ALTER COLUMN id SET DEFAULT nextval('public.current_ways_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: diary_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diary_comments ALTER COLUMN id SET DEFAULT nextval('public.diary_comments_id_seq'::regclass);


--
-- Name: diary_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diary_entries ALTER COLUMN id SET DEFAULT nextval('public.diary_entries_id_seq'::regclass);


--
-- Name: friends id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friends ALTER COLUMN id SET DEFAULT nextval('public.friends_id_seq'::regclass);


--
-- Name: gpx_file_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gpx_file_tags ALTER COLUMN id SET DEFAULT nextval('public.gpx_file_tags_id_seq'::regclass);


--
-- Name: gpx_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gpx_files ALTER COLUMN id SET DEFAULT nextval('public.gpx_files_id_seq'::regclass);


--
-- Name: issue_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_comments ALTER COLUMN id SET DEFAULT nextval('public.issue_comments_id_seq'::regclass);


--
-- Name: issues id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues ALTER COLUMN id SET DEFAULT nextval('public.issues_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: note_comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_comments ALTER COLUMN id SET DEFAULT nextval('public.note_comments_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: oauth_nonces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_nonces ALTER COLUMN id SET DEFAULT nextval('public.oauth_nonces_id_seq'::regclass);


--
-- Name: oauth_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_tokens ALTER COLUMN id SET DEFAULT nextval('public.oauth_tokens_id_seq'::regclass);


--
-- Name: redactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.redactions ALTER COLUMN id SET DEFAULT nextval('public.redactions_id_seq'::regclass);


--
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- Name: user_blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks ALTER COLUMN id SET DEFAULT nextval('public.user_blocks_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: user_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tokens ALTER COLUMN id SET DEFAULT nextval('public.user_tokens_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: acls acls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acls
    ADD CONSTRAINT acls_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: changeset_comments changeset_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.changeset_comments
    ADD CONSTRAINT changeset_comments_pkey PRIMARY KEY (id);


--
-- Name: changesets changesets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.changesets
    ADD CONSTRAINT changesets_pkey PRIMARY KEY (id);


--
-- Name: client_applications client_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_applications
    ADD CONSTRAINT client_applications_pkey PRIMARY KEY (id);


--
-- Name: current_node_tags current_node_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_node_tags
    ADD CONSTRAINT current_node_tags_pkey PRIMARY KEY (node_id, k);


--
-- Name: current_nodes current_nodes_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_nodes
    ADD CONSTRAINT current_nodes_pkey1 PRIMARY KEY (id);


--
-- Name: current_relation_members current_relation_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_relation_members
    ADD CONSTRAINT current_relation_members_pkey PRIMARY KEY (relation_id, member_type, member_id, member_role, sequence_id);


--
-- Name: current_relation_tags current_relation_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_relation_tags
    ADD CONSTRAINT current_relation_tags_pkey PRIMARY KEY (relation_id, k);


--
-- Name: current_relations current_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_relations
    ADD CONSTRAINT current_relations_pkey PRIMARY KEY (id);


--
-- Name: current_way_nodes current_way_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_way_nodes
    ADD CONSTRAINT current_way_nodes_pkey PRIMARY KEY (way_id, sequence_id);


--
-- Name: current_way_tags current_way_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_way_tags
    ADD CONSTRAINT current_way_tags_pkey PRIMARY KEY (way_id, k);


--
-- Name: current_ways current_ways_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_ways
    ADD CONSTRAINT current_ways_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: diary_comments diary_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diary_comments
    ADD CONSTRAINT diary_comments_pkey PRIMARY KEY (id);


--
-- Name: diary_entries diary_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diary_entries
    ADD CONSTRAINT diary_entries_pkey PRIMARY KEY (id);


--
-- Name: diary_entry_subscriptions diary_entry_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_pkey PRIMARY KEY (user_id, diary_entry_id);


--
-- Name: friends friends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_pkey PRIMARY KEY (id);


--
-- Name: gpx_file_tags gpx_file_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gpx_file_tags
    ADD CONSTRAINT gpx_file_tags_pkey PRIMARY KEY (id);


--
-- Name: gpx_files gpx_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gpx_files
    ADD CONSTRAINT gpx_files_pkey PRIMARY KEY (id);


--
-- Name: issue_comments issue_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_comments
    ADD CONSTRAINT issue_comments_pkey PRIMARY KEY (id);


--
-- Name: issues issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (code);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: node_tags node_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_tags
    ADD CONSTRAINT node_tags_pkey PRIMARY KEY (node_id, version, k);


--
-- Name: nodes nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nodes
    ADD CONSTRAINT nodes_pkey PRIMARY KEY (node_id, version);


--
-- Name: note_comments note_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_comments
    ADD CONSTRAINT note_comments_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: oauth_nonces oauth_nonces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_nonces
    ADD CONSTRAINT oauth_nonces_pkey PRIMARY KEY (id);


--
-- Name: oauth_tokens oauth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_pkey PRIMARY KEY (id);


--
-- Name: redactions redactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.redactions
    ADD CONSTRAINT redactions_pkey PRIMARY KEY (id);


--
-- Name: relation_members relation_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relation_members
    ADD CONSTRAINT relation_members_pkey PRIMARY KEY (relation_id, version, member_type, member_id, member_role, sequence_id);


--
-- Name: relation_tags relation_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relation_tags
    ADD CONSTRAINT relation_tags_pkey PRIMARY KEY (relation_id, version, k);


--
-- Name: relations relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relations
    ADD CONSTRAINT relations_pkey PRIMARY KEY (relation_id, version);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: user_blocks user_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_pkey PRIMARY KEY (id);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (user_id, k);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_tokens user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: way_nodes way_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.way_nodes
    ADD CONSTRAINT way_nodes_pkey PRIMARY KEY (way_id, version, sequence_id);


--
-- Name: way_tags way_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.way_tags
    ADD CONSTRAINT way_tags_pkey PRIMARY KEY (way_id, version, k);


--
-- Name: ways ways_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ways
    ADD CONSTRAINT ways_pkey PRIMARY KEY (way_id, version);


--
-- Name: acls_k_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX acls_k_idx ON public.acls USING btree (k);


--
-- Name: changeset_tags_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changeset_tags_id_idx ON public.changeset_tags USING btree (changeset_id);


--
-- Name: changesets_bbox_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_bbox_idx ON public.changesets USING gist (min_lat, max_lat, min_lon, max_lon);


--
-- Name: changesets_closed_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_closed_at_idx ON public.changesets USING btree (closed_at);


--
-- Name: changesets_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_created_at_idx ON public.changesets USING btree (created_at);


--
-- Name: changesets_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_user_id_created_at_idx ON public.changesets USING btree (user_id, created_at);


--
-- Name: changesets_user_id_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_user_id_id_idx ON public.changesets USING btree (user_id, id);


--
-- Name: current_nodes_tile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_nodes_tile_idx ON public.current_nodes USING btree (tile);


--
-- Name: current_nodes_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_nodes_timestamp_idx ON public.current_nodes USING btree ("timestamp");


--
-- Name: current_relation_members_member_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_relation_members_member_idx ON public.current_relation_members USING btree (member_type, member_id);


--
-- Name: current_relations_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_relations_timestamp_idx ON public.current_relations USING btree ("timestamp");


--
-- Name: current_way_nodes_node_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_way_nodes_node_idx ON public.current_way_nodes USING btree (node_id);


--
-- Name: current_ways_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_ways_timestamp_idx ON public.current_ways USING btree ("timestamp");


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: diary_comment_user_id_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX diary_comment_user_id_created_at_index ON public.diary_comments USING btree (user_id, created_at);


--
-- Name: diary_comments_entry_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX diary_comments_entry_id_idx ON public.diary_comments USING btree (diary_entry_id, id);


--
-- Name: diary_entry_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX diary_entry_created_at_index ON public.diary_entries USING btree (created_at);


--
-- Name: diary_entry_language_code_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX diary_entry_language_code_created_at_index ON public.diary_entries USING btree (language_code, created_at);


--
-- Name: diary_entry_user_id_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX diary_entry_user_id_created_at_index ON public.diary_entries USING btree (user_id, created_at);


--
-- Name: friends_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX friends_user_id_idx ON public.friends USING btree (user_id);


--
-- Name: gpx_file_tags_gpxid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gpx_file_tags_gpxid_idx ON public.gpx_file_tags USING btree (gpx_id);


--
-- Name: gpx_file_tags_tag_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gpx_file_tags_tag_idx ON public.gpx_file_tags USING btree (tag);


--
-- Name: gpx_files_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gpx_files_timestamp_idx ON public.gpx_files USING btree ("timestamp");


--
-- Name: gpx_files_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gpx_files_user_id_idx ON public.gpx_files USING btree (user_id);


--
-- Name: gpx_files_visible_visibility_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gpx_files_visible_visibility_idx ON public.gpx_files USING btree (visible, visibility);


--
-- Name: index_acls_on_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_acls_on_address ON public.acls USING gist (address inet_ops);


--
-- Name: index_acls_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_acls_on_domain ON public.acls USING btree (domain);


--
-- Name: index_acls_on_mx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_acls_on_mx ON public.acls USING btree (mx);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_changeset_comments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_changeset_comments_on_created_at ON public.changeset_comments USING btree (created_at);


--
-- Name: index_changesets_subscribers_on_changeset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_changesets_subscribers_on_changeset_id ON public.changesets_subscribers USING btree (changeset_id);


--
-- Name: index_changesets_subscribers_on_subscriber_id_and_changeset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_changesets_subscribers_on_subscriber_id_and_changeset_id ON public.changesets_subscribers USING btree (subscriber_id, changeset_id);


--
-- Name: index_client_applications_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_applications_on_key ON public.client_applications USING btree (key);


--
-- Name: index_client_applications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_applications_on_user_id ON public.client_applications USING btree (user_id);


--
-- Name: index_diary_entry_subscriptions_on_diary_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_diary_entry_subscriptions_on_diary_entry_id ON public.diary_entry_subscriptions USING btree (diary_entry_id);


--
-- Name: index_issue_comments_on_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issue_comments_on_issue_id ON public.issue_comments USING btree (issue_id);


--
-- Name: index_issue_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issue_comments_on_user_id ON public.issue_comments USING btree (user_id);


--
-- Name: index_issues_on_assigned_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_assigned_role ON public.issues USING btree (assigned_role);


--
-- Name: index_issues_on_reportable_type_and_reportable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_reportable_type_and_reportable_id ON public.issues USING btree (reportable_type, reportable_id);


--
-- Name: index_issues_on_reported_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_reported_user_id ON public.issues USING btree (reported_user_id);


--
-- Name: index_issues_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_status ON public.issues USING btree (status);


--
-- Name: index_issues_on_updated_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_updated_by ON public.issues USING btree (updated_by);


--
-- Name: index_note_comments_on_body; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_comments_on_body ON public.note_comments USING gin (to_tsvector('english'::regconfig, body));


--
-- Name: index_note_comments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_comments_on_created_at ON public.note_comments USING btree (created_at);


--
-- Name: index_oauth_nonces_on_nonce_and_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_nonces_on_nonce_and_timestamp ON public.oauth_nonces USING btree (nonce, "timestamp");


--
-- Name: index_oauth_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_tokens_on_token ON public.oauth_tokens USING btree (token);


--
-- Name: index_oauth_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_tokens_on_user_id ON public.oauth_tokens USING btree (user_id);


--
-- Name: index_reports_on_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_issue_id ON public.reports USING btree (issue_id);


--
-- Name: index_reports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_user_id ON public.reports USING btree (user_id);


--
-- Name: index_user_blocks_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_blocks_on_user_id ON public.user_blocks USING btree (user_id);


--
-- Name: messages_from_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_from_user_id_idx ON public.messages USING btree (from_user_id);


--
-- Name: messages_to_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_to_user_id_idx ON public.messages USING btree (to_user_id);


--
-- Name: nodes_changeset_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nodes_changeset_id_idx ON public.nodes USING btree (changeset_id);


--
-- Name: nodes_tile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nodes_tile_idx ON public.nodes USING btree (tile);


--
-- Name: nodes_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nodes_timestamp_idx ON public.nodes USING btree ("timestamp");


--
-- Name: note_comments_note_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_comments_note_id_idx ON public.note_comments USING btree (note_id);


--
-- Name: notes_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notes_created_at_idx ON public.notes USING btree (created_at);


--
-- Name: notes_tile_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notes_tile_status_idx ON public.notes USING btree (tile, status);


--
-- Name: notes_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notes_updated_at_idx ON public.notes USING btree (updated_at);


--
-- Name: points_gpxid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_gpxid_idx ON public.gps_points USING btree (gpx_id);


--
-- Name: points_tile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_tile_idx ON public.gps_points USING btree (tile);


--
-- Name: relation_members_member_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX relation_members_member_idx ON public.relation_members USING btree (member_type, member_id);


--
-- Name: relations_changeset_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX relations_changeset_id_idx ON public.relations USING btree (changeset_id);


--
-- Name: relations_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX relations_timestamp_idx ON public.relations USING btree ("timestamp");


--
-- Name: user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_id_idx ON public.friends USING btree (friend_user_id);


--
-- Name: user_roles_id_role_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_roles_id_role_unique ON public.user_roles USING btree (user_id, role);


--
-- Name: user_tokens_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_tokens_token_idx ON public.user_tokens USING btree (token);


--
-- Name: user_tokens_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_tokens_user_id_idx ON public.user_tokens USING btree (user_id);


--
-- Name: users_auth_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_auth_idx ON public.users USING btree (auth_provider, auth_uid);


--
-- Name: users_display_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_display_name_idx ON public.users USING btree (display_name);


--
-- Name: users_display_name_lower_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_display_name_lower_idx ON public.users USING btree (lower((display_name)::text));


--
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_idx ON public.users USING btree (email);


--
-- Name: users_email_lower_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_email_lower_idx ON public.users USING btree (lower((email)::text));


--
-- Name: users_home_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_home_idx ON public.users USING btree (home_tile);


--
-- Name: way_nodes_node_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX way_nodes_node_idx ON public.way_nodes USING btree (node_id);


--
-- Name: ways_changeset_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ways_changeset_id_idx ON public.ways USING btree (changeset_id);


--
-- Name: ways_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ways_timestamp_idx ON public.ways USING btree ("timestamp");


--
-- Name: changeset_comments changeset_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.changeset_comments
    ADD CONSTRAINT changeset_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: changeset_comments changeset_comments_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.changeset_comments
    ADD CONSTRAINT changeset_comments_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- Name: changeset_tags changeset_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.changeset_tags
    ADD CONSTRAINT changeset_tags_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- Name: changesets_subscribers changesets_subscribers_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.changesets_subscribers
    ADD CONSTRAINT changesets_subscribers_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- Name: changesets_subscribers changesets_subscribers_subscriber_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.changesets_subscribers
    ADD CONSTRAINT changesets_subscribers_subscriber_id_fkey FOREIGN KEY (subscriber_id) REFERENCES public.users(id);


--
-- Name: changesets changesets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.changesets
    ADD CONSTRAINT changesets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: client_applications client_applications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_applications
    ADD CONSTRAINT client_applications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: current_node_tags current_node_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_node_tags
    ADD CONSTRAINT current_node_tags_id_fkey FOREIGN KEY (node_id) REFERENCES public.current_nodes(id);


--
-- Name: current_nodes current_nodes_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_nodes
    ADD CONSTRAINT current_nodes_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- Name: current_relation_members current_relation_members_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_relation_members
    ADD CONSTRAINT current_relation_members_id_fkey FOREIGN KEY (relation_id) REFERENCES public.current_relations(id);


--
-- Name: current_relation_tags current_relation_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_relation_tags
    ADD CONSTRAINT current_relation_tags_id_fkey FOREIGN KEY (relation_id) REFERENCES public.current_relations(id);


--
-- Name: current_relations current_relations_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_relations
    ADD CONSTRAINT current_relations_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- Name: current_way_nodes current_way_nodes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_way_nodes
    ADD CONSTRAINT current_way_nodes_id_fkey FOREIGN KEY (way_id) REFERENCES public.current_ways(id);


--
-- Name: current_way_nodes current_way_nodes_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_way_nodes
    ADD CONSTRAINT current_way_nodes_node_id_fkey FOREIGN KEY (node_id) REFERENCES public.current_nodes(id);


--
-- Name: current_way_tags current_way_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_way_tags
    ADD CONSTRAINT current_way_tags_id_fkey FOREIGN KEY (way_id) REFERENCES public.current_ways(id);


--
-- Name: current_ways current_ways_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.current_ways
    ADD CONSTRAINT current_ways_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- Name: diary_comments diary_comments_diary_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diary_comments
    ADD CONSTRAINT diary_comments_diary_entry_id_fkey FOREIGN KEY (diary_entry_id) REFERENCES public.diary_entries(id);


--
-- Name: diary_comments diary_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diary_comments
    ADD CONSTRAINT diary_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: diary_entries diary_entries_language_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diary_entries
    ADD CONSTRAINT diary_entries_language_code_fkey FOREIGN KEY (language_code) REFERENCES public.languages(code);


--
-- Name: diary_entries diary_entries_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diary_entries
    ADD CONSTRAINT diary_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: diary_entry_subscriptions diary_entry_subscriptions_diary_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_diary_entry_id_fkey FOREIGN KEY (diary_entry_id) REFERENCES public.diary_entries(id);


--
-- Name: diary_entry_subscriptions diary_entry_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: friends friends_friend_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_friend_user_id_fkey FOREIGN KEY (friend_user_id) REFERENCES public.users(id);


--
-- Name: friends friends_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friends
    ADD CONSTRAINT friends_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: gps_points gps_points_gpx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gps_points
    ADD CONSTRAINT gps_points_gpx_id_fkey FOREIGN KEY (gpx_id) REFERENCES public.gpx_files(id);


--
-- Name: gpx_file_tags gpx_file_tags_gpx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gpx_file_tags
    ADD CONSTRAINT gpx_file_tags_gpx_id_fkey FOREIGN KEY (gpx_id) REFERENCES public.gpx_files(id);


--
-- Name: gpx_files gpx_files_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gpx_files
    ADD CONSTRAINT gpx_files_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: issue_comments issue_comments_issue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_comments
    ADD CONSTRAINT issue_comments_issue_id_fkey FOREIGN KEY (issue_id) REFERENCES public.issues(id);


--
-- Name: issue_comments issue_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_comments
    ADD CONSTRAINT issue_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: issues issues_reported_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_reported_user_id_fkey FOREIGN KEY (reported_user_id) REFERENCES public.users(id);


--
-- Name: issues issues_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id);


--
-- Name: issues issues_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: messages messages_from_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_from_user_id_fkey FOREIGN KEY (from_user_id) REFERENCES public.users(id);


--
-- Name: messages messages_to_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_to_user_id_fkey FOREIGN KEY (to_user_id) REFERENCES public.users(id);


--
-- Name: node_tags node_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.node_tags
    ADD CONSTRAINT node_tags_id_fkey FOREIGN KEY (node_id, version) REFERENCES public.nodes(node_id, version);


--
-- Name: nodes nodes_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nodes
    ADD CONSTRAINT nodes_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- Name: nodes nodes_redaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nodes
    ADD CONSTRAINT nodes_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES public.redactions(id);


--
-- Name: note_comments note_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_comments
    ADD CONSTRAINT note_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: note_comments note_comments_note_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_comments
    ADD CONSTRAINT note_comments_note_id_fkey FOREIGN KEY (note_id) REFERENCES public.notes(id);


--
-- Name: oauth_tokens oauth_tokens_client_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_client_application_id_fkey FOREIGN KEY (client_application_id) REFERENCES public.client_applications(id);


--
-- Name: oauth_tokens oauth_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: redactions redactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.redactions
    ADD CONSTRAINT redactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: relation_members relation_members_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relation_members
    ADD CONSTRAINT relation_members_id_fkey FOREIGN KEY (relation_id, version) REFERENCES public.relations(relation_id, version);


--
-- Name: relation_tags relation_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relation_tags
    ADD CONSTRAINT relation_tags_id_fkey FOREIGN KEY (relation_id, version) REFERENCES public.relations(relation_id, version);


--
-- Name: relations relations_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relations
    ADD CONSTRAINT relations_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- Name: relations relations_redaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relations
    ADD CONSTRAINT relations_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES public.redactions(id);


--
-- Name: reports reports_issue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_issue_id_fkey FOREIGN KEY (issue_id) REFERENCES public.issues(id);


--
-- Name: reports reports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_blocks user_blocks_moderator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_moderator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: user_blocks user_blocks_revoker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_revoker_id_fkey FOREIGN KEY (revoker_id) REFERENCES public.users(id);


--
-- Name: user_blocks user_blocks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT user_blocks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_preferences user_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_roles user_roles_granter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_granter_id_fkey FOREIGN KEY (granter_id) REFERENCES public.users(id);


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_tokens user_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: way_nodes way_nodes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.way_nodes
    ADD CONSTRAINT way_nodes_id_fkey FOREIGN KEY (way_id, version) REFERENCES public.ways(way_id, version);


--
-- Name: way_tags way_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.way_tags
    ADD CONSTRAINT way_tags_id_fkey FOREIGN KEY (way_id, version) REFERENCES public.ways(way_id, version);


--
-- Name: ways ways_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ways
    ADD CONSTRAINT ways_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);


--
-- Name: ways ways_redaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ways
    ADD CONSTRAINT ways_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES public.redactions(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('1'),
('10'),
('11'),
('12'),
('13'),
('14'),
('15'),
('16'),
('17'),
('18'),
('19'),
('2'),
('20'),
('20100513171259'),
('20100516124737'),
('20100910084426'),
('20101114011429'),
('20110322001319'),
('20110508145337'),
('20110521142405'),
('20110925112722'),
('20111116184519'),
('20111212183945'),
('20120123184321'),
('20120208122334'),
('20120208194454'),
('20120214210114'),
('20120219161649'),
('20120318201948'),
('20120328090602'),
('20120404205604'),
('20120808231205'),
('20121005195010'),
('20121012044047'),
('20121119165817'),
('20121202155309'),
('20121203124841'),
('20130328184137'),
('20131212124700'),
('20140115192822'),
('20140117185510'),
('20140210003018'),
('20140507110937'),
('20140519141742'),
('20150110152606'),
('20150111192335'),
('20150222101847'),
('20150818224516'),
('20160822153055'),
('20161002153425'),
('20161011010929'),
('20170222134109'),
('20180204153242'),
('20181020114000'),
('20181031113522'),
('20190518115041'),
('20190623093642'),
('20190702193519'),
('20190716173946'),
('20191120140058'),
('21'),
('22'),
('23'),
('24'),
('25'),
('26'),
('27'),
('28'),
('29'),
('3'),
('30'),
('31'),
('32'),
('33'),
('34'),
('35'),
('36'),
('37'),
('38'),
('39'),
('4'),
('40'),
('41'),
('42'),
('43'),
('44'),
('45'),
('46'),
('47'),
('48'),
('49'),
('5'),
('50'),
('51'),
('52'),
('53'),
('54'),
('55'),
('56'),
('57'),
('6'),
('7'),
('8'),
('9');



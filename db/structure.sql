--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.7
-- Dumped by pg_dump version 9.5.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
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


SET search_path = public, pg_catalog;

--
-- Name: format_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE format_enum AS ENUM (
    'html',
    'markdown',
    'text'
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
-- Name: issue_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE issue_status_enum AS ENUM (
    'open',
    'ignored',
    'resolved'
);


--
-- Name: note_event_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE note_event_enum AS ENUM (
    'opened',
    'closed',
    'reopened',
    'commented',
    'hidden'
);


--
-- Name: note_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE note_status_enum AS ENUM (
    'open',
    'closed',
    'hidden'
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
-- Name: maptile_for_point(bigint, bigint, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION maptile_for_point(bigint, bigint, integer) RETURNS integer
    LANGUAGE c STRICT
    AS '$libdir/libpgosm', 'maptile_for_point';


--
-- Name: tile_for_point(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION tile_for_point(integer, integer) RETURNS bigint
    LANGUAGE c STRICT
    AS '$libdir/libpgosm', 'tile_for_point';


--
-- Name: xid_to_int4(xid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION xid_to_int4(xid) RETURNS integer
    LANGUAGE c IMMUTABLE STRICT
    AS '$libdir/libpgosm', 'xid_to_int4';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: acls; Type: TABLE; Schema: public; Owner: -
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
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: changeset_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE changeset_comments (
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

CREATE SEQUENCE changeset_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: changeset_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE changeset_comments_id_seq OWNED BY changeset_comments.id;


--
-- Name: changeset_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE changeset_tags (
    changeset_id bigint NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: changesets; Type: TABLE; Schema: public; Owner: -
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
-- Name: changesets_subscribers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE changesets_subscribers (
    subscriber_id bigint NOT NULL,
    changeset_id bigint NOT NULL
);


--
-- Name: client_applications; Type: TABLE; Schema: public; Owner: -
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
    allow_write_gpx boolean DEFAULT false NOT NULL,
    allow_write_notes boolean DEFAULT false NOT NULL
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
-- Name: current_node_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE current_node_tags (
    node_id bigint NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: current_nodes; Type: TABLE; Schema: public; Owner: -
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
-- Name: current_relation_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE current_relation_members (
    relation_id bigint NOT NULL,
    member_type nwr_enum NOT NULL,
    member_id bigint NOT NULL,
    member_role character varying(255) NOT NULL,
    sequence_id integer DEFAULT 0 NOT NULL
);


--
-- Name: current_relation_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE current_relation_tags (
    relation_id bigint NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: current_relations; Type: TABLE; Schema: public; Owner: -
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
-- Name: current_way_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE current_way_nodes (
    way_id bigint NOT NULL,
    node_id bigint NOT NULL,
    sequence_id bigint NOT NULL
);


--
-- Name: current_way_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE current_way_tags (
    way_id bigint NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: current_ways; Type: TABLE; Schema: public; Owner: -
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
-- Name: diary_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE diary_comments (
    id bigint NOT NULL,
    diary_entry_id bigint NOT NULL,
    user_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    body_format format_enum DEFAULT 'markdown'::format_enum NOT NULL
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
-- Name: diary_entries; Type: TABLE; Schema: public; Owner: -
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
    visible boolean DEFAULT true NOT NULL,
    body_format format_enum DEFAULT 'markdown'::format_enum NOT NULL
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
-- Name: diary_entry_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE diary_entry_subscriptions (
    user_id bigint NOT NULL,
    diary_entry_id bigint NOT NULL
);


--
-- Name: friends; Type: TABLE; Schema: public; Owner: -
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
-- Name: gps_points; Type: TABLE; Schema: public; Owner: -
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
-- Name: gpx_file_tags; Type: TABLE; Schema: public; Owner: -
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
-- Name: gpx_files; Type: TABLE; Schema: public; Owner: -
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
-- Name: issue_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE issue_comments (
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

CREATE SEQUENCE issue_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issue_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE issue_comments_id_seq OWNED BY issue_comments.id;


--
-- Name: issues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE issues (
    id integer NOT NULL,
    reportable_type character varying NOT NULL,
    reportable_id integer NOT NULL,
    reported_user_id integer,
    status issue_status_enum DEFAULT 'open'::public.issue_status_enum NOT NULL,
    assigned_role user_role_enum NOT NULL,
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

CREATE SEQUENCE issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issues_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE issues_id_seq OWNED BY issues.id;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE languages (
    code character varying(255) NOT NULL,
    english_name character varying(255) NOT NULL,
    native_name character varying(255)
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
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
    from_user_visible boolean DEFAULT true NOT NULL,
    body_format format_enum DEFAULT 'markdown'::format_enum NOT NULL
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
-- Name: node_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE node_tags (
    node_id bigint NOT NULL,
    version bigint NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL
);


--
-- Name: nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE nodes (
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

CREATE TABLE note_comments (
    id integer NOT NULL,
    note_id bigint NOT NULL,
    visible boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    author_ip inet,
    author_id bigint,
    body text,
    event note_event_enum
);


--
-- Name: note_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE note_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: note_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE note_comments_id_seq OWNED BY note_comments.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE notes (
    id integer NOT NULL,
    latitude integer NOT NULL,
    longitude integer NOT NULL,
    tile bigint NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    status note_status_enum NOT NULL,
    closed_at timestamp without time zone
);


--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notes_id_seq OWNED BY notes.id;


--
-- Name: oauth_nonces; Type: TABLE; Schema: public; Owner: -
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
-- Name: oauth_tokens; Type: TABLE; Schema: public; Owner: -
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
    valid_to timestamp without time zone,
    allow_write_notes boolean DEFAULT false NOT NULL
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
-- Name: redactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE redactions (
    id integer NOT NULL,
    title character varying(255),
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL,
    description_format format_enum DEFAULT 'markdown'::format_enum NOT NULL
);


--
-- Name: redactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE redactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE redactions_id_seq OWNED BY redactions.id;


--
-- Name: relation_members; Type: TABLE; Schema: public; Owner: -
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
-- Name: relation_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE relation_tags (
    relation_id bigint DEFAULT 0 NOT NULL,
    k character varying(255) DEFAULT ''::character varying NOT NULL,
    v character varying(255) DEFAULT ''::character varying NOT NULL,
    version bigint NOT NULL
);


--
-- Name: relations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE relations (
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

CREATE TABLE reports (
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

CREATE SEQUENCE reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reports_id_seq OWNED BY reports.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: user_blocks; Type: TABLE; Schema: public; Owner: -
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
    updated_at timestamp without time zone,
    reason_format format_enum DEFAULT 'markdown'::format_enum NOT NULL
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
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_preferences (
    user_id bigint NOT NULL,
    k character varying(255) NOT NULL,
    v character varying(255) NOT NULL
);


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
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
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: -
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
-- Name: users; Type: TABLE; Schema: public; Owner: -
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
    auth_uid character varying(255),
    description_format format_enum DEFAULT 'markdown'::format_enum NOT NULL,
    image_fingerprint character varying(255),
    changesets_count integer DEFAULT 0 NOT NULL,
    traces_count integer DEFAULT 0 NOT NULL,
    diary_entries_count integer DEFAULT 0 NOT NULL,
    image_use_gravatar boolean DEFAULT false NOT NULL,
    image_content_type character varying(255),
    auth_provider character varying
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
-- Name: way_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE way_nodes (
    way_id bigint NOT NULL,
    node_id bigint NOT NULL,
    version bigint NOT NULL,
    sequence_id bigint NOT NULL
);


--
-- Name: way_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE way_tags (
    way_id bigint DEFAULT 0 NOT NULL,
    k character varying(255) NOT NULL,
    v character varying(255) NOT NULL,
    version bigint NOT NULL
);


--
-- Name: ways; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ways (
    way_id bigint DEFAULT 0 NOT NULL,
    changeset_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    version bigint NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    redaction_id integer
);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY acls ALTER COLUMN id SET DEFAULT nextval('acls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY changeset_comments ALTER COLUMN id SET DEFAULT nextval('changeset_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY changesets ALTER COLUMN id SET DEFAULT nextval('changesets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_applications ALTER COLUMN id SET DEFAULT nextval('client_applications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_nodes ALTER COLUMN id SET DEFAULT nextval('current_nodes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_relations ALTER COLUMN id SET DEFAULT nextval('current_relations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_ways ALTER COLUMN id SET DEFAULT nextval('current_ways_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY diary_comments ALTER COLUMN id SET DEFAULT nextval('diary_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY diary_entries ALTER COLUMN id SET DEFAULT nextval('diary_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY friends ALTER COLUMN id SET DEFAULT nextval('friends_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gpx_file_tags ALTER COLUMN id SET DEFAULT nextval('gpx_file_tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gpx_files ALTER COLUMN id SET DEFAULT nextval('gpx_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY issue_comments ALTER COLUMN id SET DEFAULT nextval('issue_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY issues ALTER COLUMN id SET DEFAULT nextval('issues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages ALTER COLUMN id SET DEFAULT nextval('messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY note_comments ALTER COLUMN id SET DEFAULT nextval('note_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notes ALTER COLUMN id SET DEFAULT nextval('notes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_nonces ALTER COLUMN id SET DEFAULT nextval('oauth_nonces_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_tokens ALTER COLUMN id SET DEFAULT nextval('oauth_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY redactions ALTER COLUMN id SET DEFAULT nextval('redactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reports ALTER COLUMN id SET DEFAULT nextval('reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_blocks ALTER COLUMN id SET DEFAULT nextval('user_blocks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_roles ALTER COLUMN id SET DEFAULT nextval('user_roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_tokens ALTER COLUMN id SET DEFAULT nextval('user_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: acls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY acls
    ADD CONSTRAINT acls_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: changeset_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changeset_comments
    ADD CONSTRAINT changeset_comments_pkey PRIMARY KEY (id);


--
-- Name: changesets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_pkey PRIMARY KEY (id);


--
-- Name: client_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_applications
    ADD CONSTRAINT client_applications_pkey PRIMARY KEY (id);


--
-- Name: current_node_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_node_tags
    ADD CONSTRAINT current_node_tags_pkey PRIMARY KEY (node_id, k);


--
-- Name: current_nodes_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_nodes
    ADD CONSTRAINT current_nodes_pkey1 PRIMARY KEY (id);


--
-- Name: current_relation_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_relation_members
    ADD CONSTRAINT current_relation_members_pkey PRIMARY KEY (relation_id, member_type, member_id, member_role, sequence_id);


--
-- Name: current_relation_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_relation_tags
    ADD CONSTRAINT current_relation_tags_pkey PRIMARY KEY (relation_id, k);


--
-- Name: current_relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_relations
    ADD CONSTRAINT current_relations_pkey PRIMARY KEY (id);


--
-- Name: current_way_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_way_nodes
    ADD CONSTRAINT current_way_nodes_pkey PRIMARY KEY (way_id, sequence_id);


--
-- Name: current_way_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_way_tags
    ADD CONSTRAINT current_way_tags_pkey PRIMARY KEY (way_id, k);


--
-- Name: current_ways_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_ways
    ADD CONSTRAINT current_ways_pkey PRIMARY KEY (id);


--
-- Name: diary_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY diary_comments
    ADD CONSTRAINT diary_comments_pkey PRIMARY KEY (id);


--
-- Name: diary_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY diary_entries
    ADD CONSTRAINT diary_entries_pkey PRIMARY KEY (id);


--
-- Name: diary_entry_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_pkey PRIMARY KEY (user_id, diary_entry_id);


--
-- Name: friends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY friends
    ADD CONSTRAINT friends_pkey PRIMARY KEY (id);


--
-- Name: gpx_file_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gpx_file_tags
    ADD CONSTRAINT gpx_file_tags_pkey PRIMARY KEY (id);


--
-- Name: gpx_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gpx_files
    ADD CONSTRAINT gpx_files_pkey PRIMARY KEY (id);


--
-- Name: issue_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY issue_comments
    ADD CONSTRAINT issue_comments_pkey PRIMARY KEY (id);


--
-- Name: issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- Name: languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (code);


--
-- Name: messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: node_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY node_tags
    ADD CONSTRAINT node_tags_pkey PRIMARY KEY (node_id, version, k);


--
-- Name: nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY nodes
    ADD CONSTRAINT nodes_pkey PRIMARY KEY (node_id, version);


--
-- Name: note_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY note_comments
    ADD CONSTRAINT note_comments_pkey PRIMARY KEY (id);


--
-- Name: notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: oauth_nonces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_nonces
    ADD CONSTRAINT oauth_nonces_pkey PRIMARY KEY (id);


--
-- Name: oauth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_tokens
    ADD CONSTRAINT oauth_tokens_pkey PRIMARY KEY (id);


--
-- Name: redactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY redactions
    ADD CONSTRAINT redactions_pkey PRIMARY KEY (id);


--
-- Name: relation_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY relation_members
    ADD CONSTRAINT relation_members_pkey PRIMARY KEY (relation_id, version, member_type, member_id, member_role, sequence_id);


--
-- Name: relation_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY relation_tags
    ADD CONSTRAINT relation_tags_pkey PRIMARY KEY (relation_id, version, k);


--
-- Name: relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY relations
    ADD CONSTRAINT relations_pkey PRIMARY KEY (relation_id, version);


--
-- Name: reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: user_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_blocks
    ADD CONSTRAINT user_blocks_pkey PRIMARY KEY (id);


--
-- Name: user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (user_id, k);


--
-- Name: user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: way_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY way_nodes
    ADD CONSTRAINT way_nodes_pkey PRIMARY KEY (way_id, version, sequence_id);


--
-- Name: way_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY way_tags
    ADD CONSTRAINT way_tags_pkey PRIMARY KEY (way_id, version, k);


--
-- Name: ways_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ways
    ADD CONSTRAINT ways_pkey PRIMARY KEY (way_id, version);


--
-- Name: acls_k_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX acls_k_idx ON acls USING btree (k);


--
-- Name: changeset_tags_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changeset_tags_id_idx ON changeset_tags USING btree (changeset_id);


--
-- Name: changesets_bbox_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_bbox_idx ON changesets USING gist (min_lat, max_lat, min_lon, max_lon);


--
-- Name: changesets_closed_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_closed_at_idx ON changesets USING btree (closed_at);


--
-- Name: changesets_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_created_at_idx ON changesets USING btree (created_at);


--
-- Name: changesets_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_user_id_created_at_idx ON changesets USING btree (user_id, created_at);


--
-- Name: changesets_user_id_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_user_id_id_idx ON changesets USING btree (user_id, id);


--
-- Name: current_nodes_tile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_nodes_tile_idx ON current_nodes USING btree (tile);


--
-- Name: current_nodes_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_nodes_timestamp_idx ON current_nodes USING btree ("timestamp");


--
-- Name: current_relation_members_member_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_relation_members_member_idx ON current_relation_members USING btree (member_type, member_id);


--
-- Name: current_relations_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_relations_timestamp_idx ON current_relations USING btree ("timestamp");


--
-- Name: current_way_nodes_node_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_way_nodes_node_idx ON current_way_nodes USING btree (node_id);


--
-- Name: current_ways_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX current_ways_timestamp_idx ON current_ways USING btree ("timestamp");


--
-- Name: diary_comment_user_id_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX diary_comment_user_id_created_at_index ON diary_comments USING btree (user_id, created_at);


--
-- Name: diary_comments_entry_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX diary_comments_entry_id_idx ON diary_comments USING btree (diary_entry_id, id);


--
-- Name: diary_entry_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX diary_entry_created_at_index ON diary_entries USING btree (created_at);


--
-- Name: diary_entry_language_code_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX diary_entry_language_code_created_at_index ON diary_entries USING btree (language_code, created_at);


--
-- Name: diary_entry_user_id_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX diary_entry_user_id_created_at_index ON diary_entries USING btree (user_id, created_at);


--
-- Name: friends_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX friends_user_id_idx ON friends USING btree (user_id);


--
-- Name: gpx_file_tags_gpxid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gpx_file_tags_gpxid_idx ON gpx_file_tags USING btree (gpx_id);


--
-- Name: gpx_file_tags_tag_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gpx_file_tags_tag_idx ON gpx_file_tags USING btree (tag);


--
-- Name: gpx_files_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gpx_files_timestamp_idx ON gpx_files USING btree ("timestamp");


--
-- Name: gpx_files_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gpx_files_user_id_idx ON gpx_files USING btree (user_id);


--
-- Name: gpx_files_visible_visibility_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX gpx_files_visible_visibility_idx ON gpx_files USING btree (visible, visibility);


--
-- Name: index_changeset_comments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_changeset_comments_on_created_at ON changeset_comments USING btree (created_at);


--
-- Name: index_changesets_subscribers_on_changeset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_changesets_subscribers_on_changeset_id ON changesets_subscribers USING btree (changeset_id);


--
-- Name: index_changesets_subscribers_on_subscriber_id_and_changeset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_changesets_subscribers_on_subscriber_id_and_changeset_id ON changesets_subscribers USING btree (subscriber_id, changeset_id);


--
-- Name: index_client_applications_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_client_applications_on_key ON client_applications USING btree (key);


--
-- Name: index_client_applications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_applications_on_user_id ON client_applications USING btree (user_id);


--
-- Name: index_diary_entry_subscriptions_on_diary_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_diary_entry_subscriptions_on_diary_entry_id ON diary_entry_subscriptions USING btree (diary_entry_id);


--
-- Name: index_issue_comments_on_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issue_comments_on_issue_id ON issue_comments USING btree (issue_id);


--
-- Name: index_issue_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issue_comments_on_user_id ON issue_comments USING btree (user_id);


--
-- Name: index_issues_on_reportable_type_and_reportable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_reportable_type_and_reportable_id ON issues USING btree (reportable_type, reportable_id);


--
-- Name: index_issues_on_reported_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_reported_user_id ON issues USING btree (reported_user_id);


--
-- Name: index_issues_on_updated_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_issues_on_updated_by ON issues USING btree (updated_by);


--
-- Name: index_note_comments_on_body; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_comments_on_body ON note_comments USING gin (to_tsvector('english'::regconfig, body));


--
-- Name: index_note_comments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_comments_on_created_at ON note_comments USING btree (created_at);


--
-- Name: index_oauth_nonces_on_nonce_and_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_nonces_on_nonce_and_timestamp ON oauth_nonces USING btree (nonce, "timestamp");


--
-- Name: index_oauth_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_tokens_on_token ON oauth_tokens USING btree (token);


--
-- Name: index_oauth_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_tokens_on_user_id ON oauth_tokens USING btree (user_id);


--
-- Name: index_reports_on_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_issue_id ON reports USING btree (issue_id);


--
-- Name: index_reports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_user_id ON reports USING btree (user_id);


--
-- Name: index_user_blocks_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_blocks_on_user_id ON user_blocks USING btree (user_id);


--
-- Name: messages_from_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_from_user_id_idx ON messages USING btree (from_user_id);


--
-- Name: messages_to_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_to_user_id_idx ON messages USING btree (to_user_id);


--
-- Name: nodes_changeset_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nodes_changeset_id_idx ON nodes USING btree (changeset_id);


--
-- Name: nodes_tile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nodes_tile_idx ON nodes USING btree (tile);


--
-- Name: nodes_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nodes_timestamp_idx ON nodes USING btree ("timestamp");


--
-- Name: note_comments_note_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_comments_note_id_idx ON note_comments USING btree (note_id);


--
-- Name: notes_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notes_created_at_idx ON notes USING btree (created_at);


--
-- Name: notes_tile_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notes_tile_status_idx ON notes USING btree (tile, status);


--
-- Name: notes_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notes_updated_at_idx ON notes USING btree (updated_at);


--
-- Name: points_gpxid_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_gpxid_idx ON gps_points USING btree (gpx_id);


--
-- Name: points_tile_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX points_tile_idx ON gps_points USING btree (tile);


--
-- Name: relation_members_member_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX relation_members_member_idx ON relation_members USING btree (member_type, member_id);


--
-- Name: relations_changeset_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX relations_changeset_id_idx ON relations USING btree (changeset_id);


--
-- Name: relations_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX relations_timestamp_idx ON relations USING btree ("timestamp");


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_id_idx ON friends USING btree (friend_user_id);


--
-- Name: user_roles_id_role_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_roles_id_role_unique ON user_roles USING btree (user_id, role);


--
-- Name: user_tokens_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_tokens_token_idx ON user_tokens USING btree (token);


--
-- Name: user_tokens_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_tokens_user_id_idx ON user_tokens USING btree (user_id);


--
-- Name: users_auth_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_auth_idx ON users USING btree (auth_provider, auth_uid);


--
-- Name: users_display_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_display_name_idx ON users USING btree (display_name);


--
-- Name: users_display_name_lower_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_display_name_lower_idx ON users USING btree (lower((display_name)::text));


--
-- Name: users_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_idx ON users USING btree (email);


--
-- Name: users_email_lower_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_email_lower_idx ON users USING btree (lower((email)::text));


--
-- Name: way_nodes_node_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX way_nodes_node_idx ON way_nodes USING btree (node_id);


--
-- Name: ways_changeset_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ways_changeset_id_idx ON ways USING btree (changeset_id);


--
-- Name: ways_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ways_timestamp_idx ON ways USING btree ("timestamp");


--
-- Name: changeset_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changeset_comments
    ADD CONSTRAINT changeset_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES users(id);


--
-- Name: changeset_comments_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changeset_comments
    ADD CONSTRAINT changeset_comments_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id);


--
-- Name: changeset_tags_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changeset_tags
    ADD CONSTRAINT changeset_tags_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id);


--
-- Name: changesets_subscribers_changeset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changesets_subscribers
    ADD CONSTRAINT changesets_subscribers_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id);


--
-- Name: changesets_subscribers_subscriber_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changesets_subscribers
    ADD CONSTRAINT changesets_subscribers_subscriber_id_fkey FOREIGN KEY (subscriber_id) REFERENCES users(id);


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
-- Name: diary_entry_subscriptions_diary_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_diary_entry_id_fkey FOREIGN KEY (diary_entry_id) REFERENCES diary_entries(id);


--
-- Name: diary_entry_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY diary_entry_subscriptions
    ADD CONSTRAINT diary_entry_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


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
-- Name: issue_comments_issue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY issue_comments
    ADD CONSTRAINT issue_comments_issue_id_fkey FOREIGN KEY (issue_id) REFERENCES issues(id);


--
-- Name: issue_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY issue_comments
    ADD CONSTRAINT issue_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: issues_reported_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY issues
    ADD CONSTRAINT issues_reported_user_id_fkey FOREIGN KEY (reported_user_id) REFERENCES users(id);


--
-- Name: issues_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY issues
    ADD CONSTRAINT issues_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES users(id);


--
-- Name: issues_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY issues
    ADD CONSTRAINT issues_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES users(id);


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
-- Name: nodes_redaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY nodes
    ADD CONSTRAINT nodes_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES redactions(id);


--
-- Name: note_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY note_comments
    ADD CONSTRAINT note_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES users(id);


--
-- Name: note_comments_note_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY note_comments
    ADD CONSTRAINT note_comments_note_id_fkey FOREIGN KEY (note_id) REFERENCES notes(id);


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
-- Name: redactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY redactions
    ADD CONSTRAINT redactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


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
-- Name: relations_redaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY relations
    ADD CONSTRAINT relations_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES redactions(id);


--
-- Name: reports_issue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT reports_issue_id_fkey FOREIGN KEY (issue_id) REFERENCES issues(id);


--
-- Name: reports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reports
    ADD CONSTRAINT reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


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
-- Name: ways_redaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ways
    ADD CONSTRAINT ways_redaction_id_fkey FOREIGN KEY (redaction_id) REFERENCES redactions(id);


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



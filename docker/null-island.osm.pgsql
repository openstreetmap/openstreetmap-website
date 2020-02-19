--
-- PostgreSQL database dump
--

-- Dumped from database version 11.7 (Debian 11.7-1.pgdg90+1)
-- Dumped by pg_dump version 11.7 (Debian 11.7-0+deb10u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users (email, id, pass_crypt, creation_time, display_name, data_public, description, home_lat, home_lon, home_zoom, nearby, pass_salt, email_valid, new_email, creation_ip, languages, status, terms_agreed, consider_pd, auth_uid, preferred_editor, terms_seen, description_format, changesets_count, traces_count, diary_entries_count, image_use_gravatar, auth_provider, home_tile, tou_agreed) VALUES ('osmosis_user_1@example.com', 1, '00000000000000000000000000000000', '2020-02-19 05:38:19.423372', 'nobody', true, 'nobody', 0, 0, 3, 50, '00000000', false, NULL, NULL, NULL, 'pending', NULL, false, NULL, NULL, false, 'markdown', 0, 0, 0, false, NULL, NULL, NULL);


--
-- Data for Name: changesets; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.changesets (id, user_id, created_at, min_lat, max_lat, min_lon, max_lon, closed_at, num_changes) VALUES (0, 1, '2020-02-19 05:38:19.423372', -900000000, 900000000, -1800000000, 1800000000, '2020-02-19 05:38:19.423372', 0);


--
-- Data for Name: changeset_tags; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.changeset_tags (changeset_id, k, v) VALUES (0, 'created_by', 'Osmosis 0.47');
INSERT INTO public.changeset_tags (changeset_id, k, v) VALUES (0, 'replication', 'true');


--
-- Data for Name: current_nodes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.current_nodes (id, latitude, longitude, changeset_id, visible, "timestamp", tile, version) VALUES (1, 0, 0, 0, true, '1970-01-01 00:00:00', 3221225472, 1);


--
-- Data for Name: current_node_tags; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.current_node_tags (node_id, k, v) VALUES (1, 'name', 'Null Island');


--
-- Data for Name: nodes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.nodes (node_id, latitude, longitude, changeset_id, visible, "timestamp", tile, version, redaction_id) VALUES (1, 0, 0, 0, true, '1970-01-01 00:00:00', 3221225472, 1, NULL);


--
-- Data for Name: node_tags; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.node_tags (node_id, version, k, v) VALUES (1, 1, 'name', 'Null Island');


--
-- Name: changesets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.changesets_id_seq', 1, false);


--
-- Name: current_nodes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.current_nodes_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--


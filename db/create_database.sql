-- MySQL dump 9.11
--
-- Host: 128.40.58.203    Database: openstreetmap
-- ------------------------------------------------------
-- Server version	5.0.38-Ubuntu_0ubuntu1-log

--
-- Table structure for table `area_segments`
--

CREATE TABLE `area_segments` (
  `id` bigint(64) NOT NULL default '0',
  `segment_id` int(11) default NULL,
  `version` bigint(20) NOT NULL default '0',
  `sequence_id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`,`version`,`sequence_id`),
  KEY `area_segments_id_idx` (`id`),
  KEY `area_segments_segment_id_idx` (`segment_id`),
  KEY `area_segments_id_version_idx` (`id`,`version`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `area_tags`
--

CREATE TABLE `area_tags` (
  `id` bigint(64) NOT NULL default '0',
  `k` varchar(255) default NULL,
  `v` varchar(255) default NULL,
  `version` bigint(20) NOT NULL default '0',
  `sequence_id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`,`version`,`sequence_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `areas`
--

CREATE TABLE `areas` (
  `id` bigint(64) NOT NULL default '0',
  `user_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  `version` bigint(20) NOT NULL auto_increment,
  `visible` tinyint(1) default '1',
  PRIMARY KEY  (`id`,`version`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `current_nodes`
--

CREATE TABLE `current_nodes` (
  `id` bigint(64) NOT NULL auto_increment,
  `latitude` double default NULL,
  `longitude` double default NULL,
  `user_id` bigint(20) default NULL,
  `visible` tinyint(1) default NULL,
  `tags` text NOT NULL,
  `timestamp` datetime default NULL,
  KEY `current_nodes_id_idx` (`id`),
  KEY `current_nodes_lat_lon_idx` (`latitude`,`longitude`),
  KEY `current_nodes_timestamp_idx` (`timestamp`)
) ENGINE=MyISAM AUTO_INCREMENT=28831962 DEFAULT CHARSET=utf8;

--
-- Table structure for table `current_segments`
--

CREATE TABLE `current_segments` (
  `id` bigint(64) NOT NULL auto_increment,
  `node_a` bigint(64) default NULL,
  `node_b` bigint(64) default NULL,
  `user_id` bigint(20) default NULL,
  `visible` tinyint(1) default NULL,
  `tags` text NOT NULL,
  `timestamp` datetime default NULL,
  KEY `current_segments_id_visible_idx` (`id`,`visible`),
  KEY `current_segments_a_idx` (`node_a`),
  KEY `current_segments_b_idx` (`node_b`)
) ENGINE=MyISAM AUTO_INCREMENT=24826942 DEFAULT CHARSET=utf8;

--
-- Table structure for table `current_way_segments`
--

CREATE TABLE `current_way_segments` (
  `id` bigint(64) default NULL,
  `segment_id` bigint(11) default NULL,
  `sequence_id` bigint(11) default NULL,
  KEY `current_way_segments_seg_idx` (`segment_id`),
  KEY `current_way_segments_id_idx` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `current_way_tags`
--

CREATE TABLE `current_way_tags` (
  `id` bigint(64) default NULL,
  `k` varchar(255) NOT NULL default '',
  `v` varchar(255) NOT NULL default '',
  KEY `current_way_tags_id_idx` (`id`),
  FULLTEXT KEY `current_way_tags_v_idx` (`v`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `current_ways`
--

CREATE TABLE `current_ways` (
  `id` bigint(64) NOT NULL auto_increment,
  `user_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  `visible` tinyint(1) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4570119 DEFAULT CHARSET=utf8;

--
-- Table structure for table `diary_entries`
--

CREATE TABLE `diary_entries` (
  `id` bigint(20) NOT NULL auto_increment,
  `user_id` bigint(20) NOT NULL,
  `title` varchar(255) default NULL,
  `body` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

--
-- Table structure for table `friends`
--

CREATE TABLE `friends` (
  `id` bigint(20) NOT NULL auto_increment,
  `user_id` bigint(20) NOT NULL,
  `friend_user_id` bigint(20) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `user_id_idx` (`friend_user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `gps_points`
--

CREATE TABLE `gps_points` (
  `altitude` float default NULL,
  `user_id` int(20) unsigned default NULL,
  `trackid` int(11) default NULL,
  `latitude` int(11) default NULL,
  `longitude` int(11) default NULL,
  `gpx_id` int(20) unsigned default NULL,
  `timestamp` datetime default NULL,
  KEY `points_idx` (`latitude`,`longitude`,`user_id`),
  KEY `points_uid_idx` (`user_id`),
  KEY `points_gpxid_idx` (`gpx_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `gpx_file_tags`
--

CREATE TABLE `gpx_file_tags` (
  `gpx_id` bigint(64) NOT NULL default '0',
  `tag` varchar(255) default NULL,
  `id` int(20) NOT NULL auto_increment,
  PRIMARY KEY  (`id`),
  KEY `gpx_file_tags_gpxid_idx` (`gpx_id`)
) ENGINE=MyISAM AUTO_INCREMENT=31675 DEFAULT CHARSET=utf8;

--
-- Table structure for table `gpx_files`
--

CREATE TABLE `gpx_files` (
  `id` bigint(64) NOT NULL auto_increment,
  `user_id` bigint(20) default NULL,
  `visible` tinyint(1) NOT NULL default '1',
  `name` varchar(255) NOT NULL default '',
  `size` bigint(20) default NULL,
  `latitude` double default NULL,
  `longitude` double default NULL,
  `timestamp` datetime default NULL,
  `public` tinyint(1) NOT NULL default '1',
  `description` varchar(255) default '',
  `inserted` tinyint(1) default NULL,
  PRIMARY KEY  (`id`),
  KEY `gpx_files_timestamp_idx` (`timestamp`),
  KEY `gpx_files_visible_public_idx` (`visible`,`public`)
) ENGINE=MyISAM AUTO_INCREMENT=22864 DEFAULT CHARSET=utf8;

--
-- Table structure for table `gpx_pending_files`
--

CREATE TABLE `gpx_pending_files` (
  `originalname` varchar(255) default NULL,
  `tmpname` varchar(255) default NULL,
  `user_id` bigint(20) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` bigint(20) NOT NULL auto_increment,
  `user_id` bigint(20) NOT NULL,
  `from_user_id` bigint(20) NOT NULL,
  `from_display_name` varchar(255) default '',
  `title` varchar(255) default NULL,
  `body` text,
  `sent_on` datetime default NULL,
  `message_read` tinyint(1) default '0',
  `to_user_id` bigint(20) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `from_name_idx` (`from_display_name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `meta_areas`
--

CREATE TABLE `meta_areas` (
  `id` bigint(64) NOT NULL auto_increment,
  `user_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

--
-- Table structure for table `nodes`
--

CREATE TABLE `nodes` (
  `id` bigint(64) default NULL,
  `latitude` double default NULL,
  `longitude` double default NULL,
  `user_id` bigint(20) default NULL,
  `visible` tinyint(1) default NULL,
  `tags` text NOT NULL,
  `timestamp` datetime default NULL,
  KEY `nodes_uid_idx` (`id`),
  KEY `nodes_latlon_idx` (`latitude`,`longitude`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `segments`
--

CREATE TABLE `segments` (
  `id` bigint(64) default NULL,
  `node_a` bigint(64) default NULL,
  `node_b` bigint(64) default NULL,
  `user_id` bigint(20) default NULL,
  `visible` tinyint(1) default NULL,
  `tags` text NOT NULL,
  `timestamp` datetime default NULL,
  KEY `street_segments_nodea_idx` (`node_a`),
  KEY `street_segments_nodeb_idx` (`node_b`),
  KEY `street_segment_uid_idx` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `email` varchar(255) default NULL,
  `id` bigint(20) NOT NULL auto_increment,
  `token` varchar(255) default NULL,
  `active` int(11) NOT NULL default '0',
  `pass_crypt` varchar(255) default NULL,
  `creation_time` datetime default NULL,
  `timeout` datetime default NULL,
  `display_name` varchar(255) default '',
  `preferences` text,
  `data_public` tinyint(1) default '0',
  `description` text NOT NULL,
  `home_lat` double default '1',
  `home_lon` double default '1',
  `within_lon` double default NULL,
  `within_lat` double default NULL,
  `home_zoom` int(2) default '3',
  PRIMARY KEY  (`id`),
  KEY `users_email_idx` (`email`),
  KEY `users_display_name_idx` (`display_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `way_segments`
--

CREATE TABLE `way_segments` (
  `id` bigint(64) NOT NULL default '0',
  `segment_id` int(11) default NULL,
  `version` bigint(20) NOT NULL default '0',
  `sequence_id` bigint(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`,`version`,`sequence_id`)
) ENGINE=MyISAM AUTO_INCREMENT=8459472 DEFAULT CHARSET=utf8;

--
-- Table structure for table `way_tags`
--

CREATE TABLE `way_tags` (
  `id` bigint(64) NOT NULL default '0',
  `k` varchar(255) default NULL,
  `v` varchar(255) default NULL,
  `version` bigint(20) default NULL,
  KEY `way_tags_id_version_idx` (`id`,`version`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `ways`
--

CREATE TABLE `ways` (
  `id` bigint(64) NOT NULL default '0',
  `user_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  `version` bigint(20) unsigned NOT NULL auto_increment,
  `visible` tinyint(1) default '1',
  PRIMARY KEY  (`id`,`version`),
  KEY `ways_id_version_idx` (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3414768 DEFAULT CHARSET=utf8;


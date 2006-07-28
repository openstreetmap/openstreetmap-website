-- MySQL dump 10.9
--
-- Host: localhost    Database: openstreetmap
-- ------------------------------------------------------
-- Server version        4.1.11-Debian_4sarge2-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `area_segments`
--

DROP TABLE IF EXISTS `area_segments`;
CREATE TABLE `area_segments` (
  `id` bigint(64) NOT NULL default '0',
  `segment_id` int(11) default NULL,
  `version` bigint(20) NOT NULL default '0',
  `sequence_id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`,`version`,`sequence_id`),
  KEY `area_segments_id_idx` (`id`),
  KEY `area_segments_segment_id_idx` (`segment_id`),
  KEY `area_segments_id_version_idx` (`id`,`version`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `area_tags`
--

DROP TABLE IF EXISTS `area_tags`;
CREATE TABLE `area_tags` (
  `id` bigint(64) NOT NULL default '0',
  `k` varchar(255) default NULL,
  `v` varchar(255) default NULL,
  `version` bigint(20) NOT NULL default '0',
  `sequence_id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`,`version`,`sequence_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `areas`
--

DROP TABLE IF EXISTS `areas`;
CREATE TABLE `areas` (
  `id` bigint(64) NOT NULL default '0',
  `user_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  `version` bigint(20) NOT NULL auto_increment,
  `visible` tinyint(1) default '1',
  PRIMARY KEY  (`id`,`version`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `current_nodes`
--

DROP TABLE IF EXISTS `current_nodes`;
CREATE TABLE `current_nodes` (
  `id` bigint(64) default NULL,
  `latitude` double default NULL,
  `longitude` double default NULL,
  `user_id` bigint(20) default NULL,
  `visible` tinyint(1) default NULL,
  `tags` text,
  `timestamp` datetime default NULL,
  KEY `current_nodes_id_idx` (`id`),
  KEY `current_nodes_lat_lon_idx` (`latitude`,`longitude`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `current_segments`
--

DROP TABLE IF EXISTS `current_segments`;
CREATE TABLE `current_segments` (
  `id` bigint(64) default NULL,
  `node_a` bigint(64) default NULL,
  `node_b` bigint(64) default NULL,
  `user_id` bigint(20) default NULL,
  `visible` tinyint(1) default NULL,
  `tags` text,
  `timestamp` datetime default NULL,
  KEY `current_segments_id_visible_idx` (`id`,`visible`),
  KEY `current_segments_a_idx` (`node_a`),
  KEY `current_segments_b_idx` (`node_b`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `current_way_segments`
--

DROP TABLE IF EXISTS `current_way_segments`;
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

DROP TABLE IF EXISTS `current_way_tags`;
CREATE TABLE `current_way_tags` (
  `id` bigint(64) default NULL,
  `k` varchar(255) default NULL,
  `v` varchar(255) default NULL,
  KEY `current_way_tags_id_idx` (`id`),
  FULLTEXT KEY `current_way_tags_v_idx` (`v`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `current_ways`
--

DROP TABLE IF EXISTS `current_ways`;
CREATE TABLE `current_ways` (
  `id` bigint(64) default NULL,
  `user_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  `visible` tinyint(1) default NULL,
  KEY `current_ways_id_visible_idx` (`id`,`visible`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `gps_points`
--

DROP TABLE IF EXISTS `gps_points`;
CREATE TABLE `gps_points` (
  `altitude` float default NULL,
  `user_id` bigint(20) default NULL,
  `trackid` int(11) default NULL,
  `latitude` double default NULL,
  `longitude` double default NULL,
  `gpx_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  KEY `points_idx` (`latitude`,`longitude`,`user_id`),
  KEY `points_uid_idx` (`user_id`),
  KEY `points_gpxid_idx` (`gpx_id`),
  KEY `gps_points_timestamp_idx` (`timestamp`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `gpx_file_tags`
--

DROP TABLE IF EXISTS `gpx_file_tags`;
CREATE TABLE `gpx_file_tags` (
  `gpx_id` bigint(64) NOT NULL default '0',
  `tag` varchar(255) default NULL,
  `sequence_id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`gpx_id`,`sequence_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `gpx_files`
--

DROP TABLE IF EXISTS `gpx_files`;
CREATE TABLE `gpx_files` (
  `id` bigint(64) NOT NULL auto_increment,
  `user_id` bigint(20) default NULL,
  `visible` tinyint(1) NOT NULL default '1',
  `name` varchar(255) NOT NULL default '',
  `size` bigint(20) default NULL,
  `latitude` double default NULL,
  `longitude` double default NULL,
  `timestamp` datetime default NULL,
  `private` tinyint(1) default '1',
  `description` varchar(255) default '',
  `tmpname` varchar(255) default NULL,
  `inserted` tinyint(1) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `gpx_pending_files`
--

DROP TABLE IF EXISTS `gpx_pending_files`;
CREATE TABLE `gpx_pending_files` (
  `originalname` varchar(255) default NULL,
  `tmpname` varchar(255) default NULL,
  `user_id` bigint(20) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `meta_areas`
--

DROP TABLE IF EXISTS `meta_areas`;
CREATE TABLE `meta_areas` (
  `id` bigint(64) NOT NULL auto_increment,
  `user_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `meta_nodes`
--

DROP TABLE IF EXISTS `meta_nodes`;
CREATE TABLE `meta_nodes` (
  `id` bigint(64) NOT NULL auto_increment,
  `user_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `meta_segments`
--

DROP TABLE IF EXISTS `meta_segments`;
CREATE TABLE `meta_segments` (
  `id` bigint(64) NOT NULL auto_increment,
  `user_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `meta_ways`
--

DROP TABLE IF EXISTS `meta_ways`;
CREATE TABLE `meta_ways` (
  `id` bigint(64) NOT NULL auto_increment,
  `user_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `nodes`
--

DROP TABLE IF EXISTS `nodes`;
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

DROP TABLE IF EXISTS `segments`;
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

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `email` varchar(255) default NULL,
  `id` bigint(20) NOT NULL auto_increment,
  `token` varchar(255) default NULL,
  `active` int(11) NOT NULL default '0',
  `pass_crypt` varchar(255) default NULL,
  `creation_time` datetime default NULL,
  `timeout` datetime default NULL,
  `display_name` varchar(255) default '',
  PRIMARY KEY  (`id`),
  KEY `users_email_idx` (`email`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `way_segments`
--

DROP TABLE IF EXISTS `way_segments`;
CREATE TABLE `way_segments` (
  `id` bigint(64) NOT NULL default '0',
  `segment_id` int(11) default NULL,
  `version` bigint(20) NOT NULL default '0',
  `sequence_id` bigint(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`,`version`,`sequence_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `way_tags`
--

DROP TABLE IF EXISTS `way_tags`;
CREATE TABLE `way_tags` (
  `id` bigint(64) NOT NULL default '0',
  `k` varchar(255) default NULL,
  `v` varchar(255) default NULL,
  `version` bigint(20) default NULL,
  KEY `way_tags_id_version_idx` (`id`,`version`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `ways`
--

DROP TABLE IF EXISTS `ways`;
CREATE TABLE `ways` (
  `id` bigint(64) NOT NULL default '0',
  `user_id` bigint(20) default NULL,
  `timestamp` datetime default NULL,
  `version` bigint(20) unsigned NOT NULL auto_increment,
  `visible` tinyint(1) default '1',
  PRIMARY KEY  (`id`,`version`),
  KEY `ways_id_version_idx` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
-- MySQL dump 9.11
--
-- Host: localhost    Database: file_column_test
-- ------------------------------------------------------
-- Server version	4.0.24

--
-- Table structure for table `entries`
--

DROP TABLE IF EXISTS entries;
CREATE TABLE entries (
  id int(11) NOT NULL auto_increment,
  image varchar(200) default NULL,
  file varchar(200) NOT NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

DROP TABLE IF EXISTS movies;
CREATE TABLE movies (
  id int(11) NOT NULL auto_increment,
  movie varchar(200) default NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;


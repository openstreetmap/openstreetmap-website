/* this script when run on the current db migrates it to rails */

drop table meta_nodes;
alter table current_nodes modify tags text not null;
alter table current_nodes modify id bigint(64) not null auto_increment;
alter table nodes modify tags text not null;

drop table meta_segments;
alter table current_segments modify tags text not null;
alter table current_segments modify id bigint(64) not null auto_increment;
alter table segments modify tags text not null;

drop table meta_ways;
alter table current_ways drop index current_ways_id_visible_idx;
alter table current_ways modify id bigint(64) not null auto_increment, add primary key(id);

alter table current_way_tags change k k varchar(255) not null default '';
alter table current_way_tags change v v varchar(255) not null default '';

alter table gpx_files change private public boolean default 1 not null;
update gpx_files set public = !public;
create index gpx_files_visible_public_idx on gpx_files(visible, public);

alter table gpx_file_tags change sequence_id sequence_id int(11);
alter table gpx_file_tags drop primary key;
alter table gpx_file_tags drop column sequence_id;
create index gpx_file_tags_gpxid_idx on gpx_file_tags(gpx_id);
alter table gpx_file_tags add id int(20) auto_increment not null, add primary key(id);

alter table users add preferences text;
create index users_display_name_idx on users(display_name);

alter table users add data_public boolean default false;

alter table gpx_files drop column tmpname;

alter table users add column description text not null;
create table diary_entries(id bigint not null auto_increment, user_id bigint not null, title varchar(255), body text, primary key(id));
alter table diary_entries add created_at datetime;
alter table diary_entries add updated_at datetime;




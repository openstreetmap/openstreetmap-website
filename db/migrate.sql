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


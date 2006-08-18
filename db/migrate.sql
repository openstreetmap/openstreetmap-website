drop table meta_nodes;
alter table current_nodes modify tags text not null;
alter table current_nodes modify id bigint(64) not null auto_increment;


alter table nodes modify tags text not null;


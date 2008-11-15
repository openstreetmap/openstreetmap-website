create table reference_types (
    reference_type_id integer primary key,
    type_label varchar(50) default null,
    abbreviation varchar(50) default null,
    description varchar(50) default null
);

create table reference_codes (
    reference_type_id int(11),
    reference_code int(11) not null,
    code_label varchar(50) default null,
    abbreviation varchar(50) default null,
    description varchar(50) default null,
    primary key (reference_type_id, reference_code)
);

create table products (
    id int(11) not null primary key,
    name varchar(50) default null
);

create table tariffs (
    tariff_id int(11) not null,
    start_date date not null,
    amount integer(11) default null,
    primary key (tariff_id, start_date)
);

create table product_tariffs (
    product_id int(11) not null,
    tariff_id int(11) not null,
    tariff_start_date date not null,
    primary key (product_id, tariff_id, tariff_start_date)
);

create table suburbs (
    city_id int(11) not null,
    suburb_id int(11) not null,
    name varchar(50) not null,
    primary key (city_id, suburb_id)
);

create table streets (
    id integer not null primary key autoincrement,
    city_id int(11) not null,
    suburb_id int(11) not null,
    name varchar(50) not null
);

create table users (
    id integer not null primary key autoincrement,
    name varchar(50) not null
);

create table articles (
    id integer not null primary key autoincrement,
    name varchar(50) not null
);

create table readings (
    id integer not null primary key autoincrement,
    user_id int(11) not null,
    article_id int(11) not null,
    rating int(11) not null
);

create table groups (
    id integer not null primary key autoincrement,
    name varchar(50) not null
);

create table memberships (
    user_id int not null,
    group_id int not null,
    primary key (user_id, group_id)
);

create table membership_statuses (
    id integer not null primary key autoincrement,
    user_id int not null,
    group_id int not null,
	status varchar(50) not null
);

create table departments (
    department_id integer not null,
    location_id integer not null,
    primary key (department_id, location_id)
);

create table employees (
    id integer not null primary key autoincrement,
    department_id integer null,
    location_id integer null
);

create table comments (
	id integer not null primary key autoincrement,
	person_id varchar(100) null,
	person_type varchar(100) null,
	hack_id varchar(100) null
);

create table hacks (
    name varchar(50) not null primary key
);

create table kitchen_sinks (
	id_1 integer not null,
	id_2 integer not null,
	a_date date,
	a_string varchar(100),
	primary key (id_1, id_2)
);

create table restaurants (
	franchise_id integer not null,
	store_id integer not null,
	name varchar(100),
	primary key (franchise_id, store_id)
);

create table restaurants_suburbs (
	franchise_id integer not null,
	store_id integer not null,
	city_id integer not null,
	suburb_id integer not null
);

create table dorms (
	id integer not null primary key autoincrement
);

create table rooms (
	dorm_id integer not null,
	room_id integer not null,
	primary key (dorm_id, room_id)
);

create table room_attributes (
	id integer not null primary key autoincrement,
	name varchar(50)
);

create table room_attribute_assignments (
	dorm_id integer not null,
	room_id integer not null,
	room_attribute_id integer not null
);

create table students (
	id integer not null primary key autoincrement
);

create table room_assignments (
	student_id integer not null,
	dorm_id integer not null,
	room_id integer not null	
);


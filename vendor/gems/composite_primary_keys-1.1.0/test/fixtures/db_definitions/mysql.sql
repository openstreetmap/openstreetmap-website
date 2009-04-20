create table reference_types (
    reference_type_id int(11) not null auto_increment,
    type_label varchar(50) default null,
    abbreviation varchar(50) default null,
    description varchar(50) default null,
    primary key (reference_type_id)
) type=InnoDB;

create table reference_codes (
    reference_type_id int(11),
    reference_code int(11) not null,
    code_label varchar(50) default null,
    abbreviation varchar(50) default null,
    description varchar(50) default null,
    primary key (reference_type_id, reference_code)
) type=InnoDB;

create table products (
    id int(11) not null auto_increment,
    name varchar(50) default null,
    primary key (id)
) type=InnoDB;

create table tariffs (
    tariff_id int(11) not null,
    start_date date not null,
    amount integer(11) default null,
    primary key (tariff_id, start_date)
) type=InnoDB;

create table product_tariffs (
    product_id int(11) not null,
    tariff_id int(11) not null,
    tariff_start_date date not null,
    primary key (product_id, tariff_id, tariff_start_date)
) type=InnoDB;

create table suburbs (
    city_id int(11) not null,
    suburb_id int(11) not null,
    name varchar(50) not null,
    primary key (city_id, suburb_id)
) type=InnoDB;

create table streets (
    id int(11) not null auto_increment,
    city_id int(11) not null,
    suburb_id int(11) not null,
    name varchar(50) not null,
    primary key (id)
) type=InnoDB;

create table users (
    id int(11) not null auto_increment,
    name varchar(50) not null,
    primary key (id)
) type=InnoDB;

create table articles (
    id int(11) not null auto_increment,
    name varchar(50) not null,
    primary key (id)
) type=InnoDB;

create table readings (
    id int(11) not null auto_increment,
    user_id int(11) not null,
    article_id int(11) not null,
    rating int(11) not null,
    primary key (id)
) type=InnoDB;

create table groups (
    id int(11) not null auto_increment,
    name varchar(50) not null,
    primary key (id)
) type=InnoDB;

create table memberships (
    user_id int(11) not null,
    group_id int(11) not null,
    primary key  (user_id,group_id)
) type=InnoDB;

create table membership_statuses (
    id int(11) not null auto_increment,
    user_id int(11) not null,
    group_id int(11) not null,
    status varchar(50) not null,
    primary key (id)
) type=InnoDB;

create table departments (
    department_id int(11) not null,
    location_id int(11) not null,
    primary key (department_id, location_id)
) type=InnoDB;

create table employees (
    id int(11) not null auto_increment,
    department_id int(11) default null,
    location_id int(11) default null,
    primary key (id)
) type=InnoDB;

create table comments (
    id int(11) not null auto_increment,
    person_id varchar(100) default null,
    person_type varchar(100) default null,
    hack_id varchar(100) default null,
    primary key (id)
) type=InnoDB;

create table hacks (
    name varchar(50) not null,
    primary key (name)
) type=InnoDB;

create table kitchen_sinks (
    id_1 int(11) not null,
    id_2 int(11) not null,
    a_date date,
    a_string varchar(100),
    primary key (id_1, id_2)
) type=InnoDB;

create table restaurants (
    franchise_id int(11) not null,
    store_id int(11) not null,
    name varchar(100),
    primary key (franchise_id, store_id)
) type=InnoDB;

create table restaurants_suburbs (
    franchise_id int(11) not null,
    store_id int(11) not null,
    city_id int(11) not null,
    suburb_id int(11) not null
) type=InnoDB;

create table dorms (
    id int(11) not null auto_increment,
    primary key(id)
) type=InnoDB;

create table rooms (
    dorm_id int(11) not null,
    room_id int(11) not null,
    primary key (dorm_id, room_id)
) type=InnoDB;

create table room_attributes (
    id int(11) not null auto_increment,
    name varchar(50),
    primary key(id)
) type=InnoDB;

create table room_attribute_assignments (
    dorm_id int(11) not null,
    room_id int(11) not null,
    room_attribute_id int(11) not null
) type=InnoDB;

create table students (
    id int(11) not null auto_increment,
    primary key(id)
) type=InnoDB;

create table room_assignments (
    student_id int(11) not null,
    dorm_id int(11) not null,
    room_id int(11) not null
) type=InnoDB;


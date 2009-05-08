create sequence public.reference_types_seq start 1000;

create table reference_types (
    reference_type_id int         default nextval('public.reference_types_seq'),
    type_label        varchar(50) default null,
    abbreviation      varchar(50) default null,
    description       varchar(50) default null,
    primary key (reference_type_id)
);

create table reference_codes (
    reference_type_id int,
    reference_code    int         not null,
    code_label        varchar(50) default null,
    abbreviation      varchar(50) default null,
    description       varchar(50) default null
);

create sequence public.products_seq start 1000;

create table products (
    id   int         not null default nextval('public.products_seq'),
    name varchar(50) default null,
    primary key (id)
);

create table tariffs (
    tariff_id  int  not null,
    start_date date not null,
    amount     int  default null,
    primary key (tariff_id, start_date)
);

create table product_tariffs (
    product_id        int  not null,
    tariff_id         int  not null,
    tariff_start_date date not null,
    primary key (product_id, tariff_id, tariff_start_date)
);

create table suburbs (
    city_id   int         not null,
    suburb_id int         not null,
    name      varchar(50) not null,
    primary key (city_id, suburb_id)
);

create sequence public.streets_seq start 1000;

create table streets (
    id        int         not null default nextval('public.streets_seq'),
    city_id   int         not null,
    suburb_id int         not null,
    name      varchar(50) not null,
    primary key (id)
);

create sequence public.users_seq start 1000;

create table users (
    id   int         not null default nextval('public.users_seq'),
    name varchar(50) not null,
    primary key (id)
);

create sequence public.articles_seq start 1000;

create table articles (
    id   int         not null default nextval('public.articles_seq'),
    name varchar(50) not null,
    primary key (id)
);

create sequence public.readings_seq start 1000;

create table readings (
    id         int not null default nextval('public.readings_seq'),
    user_id    int not null,
    article_id int not null,
    rating     int not null,
    primary key (id)
);

create sequence public.groups_seq start 1000;

create table groups (
    id   int         not null default nextval('public.groups_seq'),
    name varchar(50) not null,
    primary key (id)
);

create table memberships (
    user_id  int not null,
    group_id int not null,
    primary key (user_id, group_id)
);

create sequence public.membership_statuses_seq start 1000;

create table membership_statuses (
    id       int         not null default nextval('public.membership_statuses_seq'),
    user_id  int         not null,
    group_id int         not null,
    status   varchar(50) not null,
    primary key (id)
);

create table departments (
    department_id int not null,
    location_id   int not null,
    primary key (department_id, location_id)
);

create sequence public.employees_seq start 1000;

create table employees (
    id            int not null default nextval('public.employees_seq'),
    department_id int default null,
    location_id   int default null,
    primary key (id)
);

create sequence public.comments_seq start 1000;

create table comments (
    id          int          not null default nextval('public.comments_seq'),
    person_id   varchar(100) default null,
    person_type varchar(100) default null,
    hack_id     varchar(100) default null,
    primary key (id)
);

create table hacks (
    name varchar(50) not null,
    primary key (name)
);

create table kitchen_sinks (
    id_1   int not null,
    id_2   int not null,
    a_date date,
    a_string varchar(100),
    primary key (id_1, id_2)
);

create table restaurants (
    franchise_id int not null,
    store_id     int not null,
    name         varchar(100),
    primary key (franchise_id, store_id)
);

create table restaurants_suburbs (
    franchise_id int not null,
    store_id     int not null,
    city_id      int not null,
    suburb_id    int not null
);

create sequence public.dorms_seq start 1000;

create table dorms (
    id int not null default nextval('public.dorms_seq'),
    primary key (id)
);

create table rooms (
    dorm_id int not null,
    room_id int not null,
    primary key (dorm_id, room_id)
);

create sequence public.room_attributes_seq start 1000;

create table room_attributes (
    id   int not null default nextval('public.room_attributes_seq'),
    name varchar(50),
    primary key (id)
);

create table room_attribute_assignments (
    dorm_id           int not null,
    room_id           int not null,
    room_attribute_id int not null
);

create sequence public.students_seq start 1000;

create table students (
    id int not null default nextval('public.students_seq'),
    primary key (id)
);

create table room_assignments (
    student_id int not null,
    dorm_id    int not null,
    room_id    int not null
);


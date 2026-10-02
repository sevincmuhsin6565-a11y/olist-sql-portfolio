-- Olist Brazilian E-Commerce Dataset (Kaggle)
-- Tables imported into PostgreSQL via DataGrip.
-- geolocation table excluded (out of scope).

create table public.customers
(
    customer_id              varchar(50) not null
        primary key,
    customer_unique_id       varchar(50),
    customer_zip_code_prefix varchar(20),
    customer_city            varchar(255),
    customer_state           varchar(5)
);

alter table public.customers
    owner to postgres;

create table public.sellers
(
    seller_id              varchar(50) not null
        primary key,
    seller_zip_code_prefix varchar(20),
    seller_city            varchar(255),
    seller_state           varchar(5)
);

alter table public.sellers
    owner to postgres;

create table public.products
(
    product_id                 varchar(50) not null
        primary key,
    product_category_name      varchar(255),
    product_name_lenght        integer,
    product_description_lenght integer,
    product_photos_qty         integer,
    product_weight_g           integer,
    product_length_cm          integer,
    product_height_cm          integer,
    product_width_cm           integer
);

alter table public.products
    owner to postgres;

create table public.product_category_translation
(
    product_category_name         varchar(255) not null
        primary key,
    product_category_name_english varchar(255)
);

alter table public.product_category_translation
    owner to postgres;

create table public.orders
(
    order_id                      varchar(50) not null
        primary key,
    customer_id                   varchar(50),
    order_status                  varchar(50),
    order_purchase_timestamp      timestamp,
    order_approved_at             timestamp,
    order_delivered_carrier_date  timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp
);

alter table public.orders
    owner to postgres;

create table public.order_items
(
    order_id            varchar(50) not null,
    order_item_id       integer     not null,
    product_id          varchar(50),
    seller_id           varchar(50),
    shipping_limit_date timestamp,
    price               numeric(10, 2),
    freight_value       numeric(10, 2),
    primary key (order_id, order_item_id)
);

alter table public.order_items
    owner to postgres;

create table public.order_payments
(
    order_id             varchar(50),
    payment_sequential   integer,
    payment_type         varchar(50),
    payment_installments integer,
    payment_value        numeric(10, 2)
);

alter table public.order_payments
    owner to postgres;

create table public.order_reviews
(
    review_id               varchar(50),
    order_id                varchar(50),
    review_score            integer,
    review_comment_title    text,
    review_comment_message  text,
    review_creation_date    timestamp,
    review_answer_timestamp timestamp
);

alter table public.order_reviews
    owner to postgres;


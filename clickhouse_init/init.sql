-- Таблица для "прослушки" Kafka
CREATE TABLE IF NOT EXISTS default.events_queue (
    `timestamp` DateTime, `user_id` String, `ip_address` IPv4, `url` Nullable(String),
    `element_id` Nullable(String), `duration_seconds` Nullable(UInt32),
    `order_id` Nullable(String), `amount` Nullable(Float64)
) ENGINE = Kafka SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'user_clicks,page_views,orders',
    kafka_group_name = 'clickhouse_router_group',
    kafka_format = 'JSONEachRow';

-- Таблицы для хранения.
CREATE TABLE IF NOT EXISTS default.clicks_table (
    `timestamp` DateTime,
    `user_id` String,
    `ip_address` IPv4,
    `url` String,
    `element_id` String
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, user_id);

CREATE TABLE IF NOT EXISTS default.views_table (
    `timestamp` DateTime,
    `user_id` String,
    `ip_address` IPv4,
    `url` String,
    `duration_seconds` UInt32
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, user_id);

CREATE TABLE IF NOT EXISTS default.orders_table (
    `timestamp` DateTime,
    `order_id` String,
    `user_id` String,
    `ip_address` IPv4,
    `amount` Float64
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, order_id);

-- Каждое представление слушает свой топик и перенаправляет данные в свою таблицу.
CREATE MATERIALIZED VIEW IF NOT EXISTS default.clicks_mv TO default.clicks_table AS
SELECT timestamp, user_id, ip_address, url, element_id
FROM default.events_queue
WHERE _topic = 'user_clicks';

CREATE MATERIALIZED VIEW IF NOT EXISTS default.views_mv TO default.views_table AS
SELECT timestamp, user_id, ip_address, url, duration_seconds
FROM default.events_queue
WHERE _topic = 'page_views';

CREATE MATERIALIZED VIEW IF NOT EXISTS default.orders_mv TO default.orders_table AS
SELECT timestamp, order_id, user_id, ip_address, amount
FROM default.events_queue
WHERE _topic = 'orders';
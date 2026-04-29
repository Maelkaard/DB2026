DROP SCHEMA IF EXISTS sem11 CASCADE;
CREATE SCHEMA sem11;

CREATE TABLE sem11.customer (
    customer_id      INTEGER PRIMARY KEY,
    full_name        TEXT NOT NULL,
    city             TEXT NOT NULL,
    registration_dt  DATE NOT NULL,
    email            TEXT NOT NULL UNIQUE
);

CREATE TABLE sem11.category (
    category_id    INTEGER PRIMARY KEY,
    category_name  TEXT NOT NULL UNIQUE
);

CREATE TABLE sem11.product (
    product_id     INTEGER PRIMARY KEY,
    product_name   TEXT NOT NULL,
    category_id    INTEGER NOT NULL REFERENCES sem11.category(category_id),
    price          NUMERIC(10,2) NOT NULL CHECK (price > 0),
    stock_qty      INTEGER NOT NULL CHECK (stock_qty >= 0),
    is_active      BOOLEAN NOT NULL
);

CREATE TABLE sem11.order (
    order_id        BIGINT PRIMARY KEY,
    customer_id     INTEGER NOT NULL REFERENCES sem11.customer(customer_id),
    order_dt        DATE NOT NULL,
    status          TEXT NOT NULL CHECK (status IN ('new', 'paid', 'shipped', 'cancelled')),
    total_amount    NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0)
);

CREATE TABLE sem11.order_item (
    order_item_id   BIGINT PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES sem11.order(order_id),
    product_id      INTEGER NOT NULL REFERENCES sem11.product(product_id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10,2) NOT NULL CHECK (unit_price > 0)
);

INSERT INTO sem11.category (category_id, category_name) VALUES
(1, 'Books'),
(2, 'Electronics'),
(3, 'Home'),
(4, 'Sports'),
(5, 'Toys'),
(6, 'Garden'),
(7, 'Beauty'),
(8, 'Office'),
(9, 'Pet Supplies'),
(10, 'Automotive');

INSERT INTO sem11.customer (customer_id, full_name, city, registration_dt, email)
SELECT
    g,
    'Customer ' || g,
    CASE
        WHEN g % 10 IN (0, 1, 2) THEN 'Berlin'
        WHEN g % 10 IN (3, 4) THEN 'Munich'
        WHEN g % 10 = 5 THEN 'Hamburg'
        WHEN g % 10 = 6 THEN 'Cologne'
        WHEN g % 10 = 7 THEN 'Leipzig'
        WHEN g % 10 = 8 THEN 'Dresden'
        ELSE 'Bremen'
    END,
    DATE '2023-01-01' + (g % 900),
    'customer' || g || '@mail.test'
FROM generate_series(1, 5000) AS g;

INSERT INTO sem11.product (product_id, product_name, category_id, price, stock_qty, is_active)
SELECT
    g,
    'Product ' || g,
    ((g - 1) % 10) + 1,
    ((g % 200) + 5) * 3 + ((g % 7) * 0.99)::numeric(10,2),
    (g * 11) % 120,
    (g % 17 <> 0)
FROM generate_series(1, 2000) AS g;

INSERT INTO sem11.order(order_id, customer_id, order_dt, status, total_amount)
SELECT
    g,
    ((g * 37) % 5000) + 1,
    DATE '2024-01-01' + (g % 731),
    CASE
        WHEN g % 20 = 0 THEN 'cancelled'
        WHEN g % 10 IN (1, 2) THEN 'new'
        WHEN g % 10 IN (3, 4, 5) THEN 'paid'
        ELSE 'shipped'
    END,
    0
FROM generate_series(1, 100000) AS g;

INSERT INTO sem11.order_item (order_item_id, order_id, product_id, quantity, unit_price)
SELECT
    (o.order_id - 1) * 3 + s.n,
    o.order_id,
    ((o.order_id * 13 + s.n * 17) % 2000) + 1,
    ((o.order_id + s.n) % 4) + 1,
    p.price
FROM sem11.order o
CROSS JOIN generate_series(1, 3) AS s(n)
JOIN sem11.product p
  ON p.product_id = ((o.order_id * 13 + s.n * 17) % 2000) + 1;

UPDATE sem11.order oh
SET total_amount = x.total_amount
FROM (
    SELECT
        oi.order_id,
        SUM(oi.quantity * oi.unit_price)::numeric(12,2) AS total_amount
    FROM sem11.order_item oi
    GROUP BY oi.order_id
) AS x
WHERE x.order_id = oh.order_id;

CREATE INDEX idx_sem11_customer_email ON sem11.customer(email);
CREATE INDEX idx_sem11_customer_city ON sem11.customer(city);
CREATE INDEX idx_sem11_customer_city_regdt ON sem11.customer(city, registration_dt);
CREATE INDEX idx_sem11_product_category_price ON sem11.product(category_id, price);
CREATE INDEX idx_sem11_product_active ON sem11.product(is_active);
CREATE INDEX idx_sem11_order_customer_id ON sem11.order(customer_id);
CREATE INDEX idx_sem11_order_status ON sem11.order(status);
CREATE INDEX idx_sem11_order_order_dt ON sem11.order(order_dt);
CREATE INDEX idx_sem11_order_customer_dt ON sem11.order(customer_id, order_dt);
CREATE INDEX idx_sem11_order_item_order_id ON sem11.order_item(order_id);
CREATE INDEX idx_sem11_order_item_product_id ON sem11.order_item(product_id);
CREATE INDEX idx_sem11_order_item_product_order ON sem11.order_item(product_id, order_id);
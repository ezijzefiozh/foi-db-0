-- =========================================================
--  ONLINE STORE DATABASE
--  Script 1 of 3 : Schema Creation
--  DBMS        : PostgreSQL 18
--  Reference   : ERD_OnlineStore.mermaid
-- =========================================================
--
--  Relationships implemented below
--  --------------------------------
--  Categories (1) ----------- (N) Products
--  Customers  (1) ----------- (N) Orders
--  Orders     (1) ----------- (N) Order_Items
--  Products   (1) ----------- (N) Order_Items
--  Orders     (1) ----------- (N) Payments
--
-- =========================================================

-- ---------------------------------------------------------
-- Drop existing tables (children first, then parents)
-- so the script can be re-run from a clean state.
-- ---------------------------------------------------------
DROP TABLE IF EXISTS payments    CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders      CASCADE;
DROP TABLE IF EXISTS products    CASCADE;
DROP TABLE IF EXISTS categories  CASCADE;
DROP TABLE IF EXISTS customers   CASCADE;


-- ---------------------------------------------------------
-- Table: customers
-- One customer can place many orders.
-- ---------------------------------------------------------
CREATE TABLE customers (
    customer_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    address       VARCHAR(255),
    created_at    DATE NOT NULL DEFAULT CURRENT_DATE
);


-- ---------------------------------------------------------
-- Table: categories
-- One category can group many products.
-- ---------------------------------------------------------
CREATE TABLE categories (
    category_id   SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,
    description   VARCHAR(255)
);


-- ---------------------------------------------------------
-- Table: products
-- Each product belongs to exactly one category.
-- ON DELETE RESTRICT: a category in use cannot be deleted.
-- ---------------------------------------------------------
CREATE TABLE products (
    product_id     SERIAL PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    description     TEXT,
    price           NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    stock_quantity  INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    category_id     INTEGER NOT NULL,
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);


-- ---------------------------------------------------------
-- Table: orders
-- Each order belongs to exactly one customer.
-- status is restricted to a fixed workflow of values.
-- ---------------------------------------------------------
CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INTEGER NOT NULL,
    order_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    status        VARCHAR(20) NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'processing', 'shipped',
                                     'delivered', 'cancelled')),
    total_amount  NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);


-- ---------------------------------------------------------
-- Table: order_items
-- Junction table resolving the many-to-many relationship
-- between orders and products.
-- unit_price freezes the product price at purchase time,
-- so later price changes never distort historical orders.
-- uq_order_product prevents the same product being added
-- to an order twice as two separate rows.
-- ---------------------------------------------------------
CREATE TABLE order_items (
    order_item_id  SERIAL PRIMARY KEY,
    order_id       INTEGER NOT NULL,
    product_id     INTEGER NOT NULL,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    CONSTRAINT fk_orderitems_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_orderitems_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_order_product UNIQUE (order_id, product_id)
);


-- ---------------------------------------------------------
-- Table: payments
-- Each payment settles exactly one order. Modelled as a
-- separate table (rather than columns on orders) so an
-- order can, in principle, have more than one payment
-- (e.g. partial payment, retry after a failed attempt).
-- ---------------------------------------------------------
CREATE TABLE payments (
    payment_id      SERIAL PRIMARY KEY,
    order_id        INTEGER NOT NULL,
    payment_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    amount          NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    payment_method  VARCHAR(20) NOT NULL
                    CHECK (payment_method IN ('card', 'paypal',
                                               'bank_transfer',
                                               'cash_on_delivery')),
    status          VARCHAR(20) NOT NULL DEFAULT 'completed'
                    CHECK (status IN ('pending', 'completed',
                                       'failed', 'refunded')),
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);


-- ---------------------------------------------------------
-- Indexes on foreign key columns.
-- PostgreSQL does not index FK columns automatically, and
-- every one of these columns is used as a JOIN key in
-- 03_queries.sql, so they are indexed explicitly here.
-- ---------------------------------------------------------
CREATE INDEX idx_products_category   ON products (category_id);
CREATE INDEX idx_orders_customer     ON orders (customer_id);
CREATE INDEX idx_orderitems_order    ON order_items (order_id);
CREATE INDEX idx_orderitems_product  ON order_items (product_id);
CREATE INDEX idx_payments_order      ON payments (order_id);

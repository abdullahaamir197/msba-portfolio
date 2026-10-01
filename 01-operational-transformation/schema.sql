-- ============================================================================
-- 1. PARENT / MASTER ENTITIES (MUST BE CREATED FIRST)
-- ============================================================================

CREATE TABLE customers (
    customer_id                 VARCHAR(50) PRIMARY KEY,
    customer_unique_id          VARCHAR(50) NOT NULL,
    customer_zip_code_prefix    VARCHAR(10) NOT NULL,
    customer_city               VARCHAR(100) NOT NULL,
    customer_state              VARCHAR(2) NOT NULL
);

CREATE TABLE sellers (
    seller_id                   VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix      VARCHAR(10) NOT NULL,
    seller_city                 VARCHAR(100) NOT NULL,
    seller_state                VARCHAR(2) NOT NULL
);

CREATE TABLE products (
    product_id                  VARCHAR(50) PRIMARY KEY,
    product_category_name       VARCHAR(100),
    product_weight_g            DECIMAL(10, 2)
);

-- ============================================================================
-- 2. TRANSACTIONAL SPINE (ORDER LIFECYCLE)
-- ============================================================================

CREATE TABLE orders (
    order_id                        VARCHAR(50) PRIMARY KEY,
    customer_id                     VARCHAR(50) NOT NULL REFERENCES customers(customer_id),
    order_status                    VARCHAR(30) NOT NULL,
    order_purchase_timestamp        TIMESTAMP NOT NULL,
    order_delivered_carrier_date    TIMESTAMP,             -- NULLABLE (package in transit)
    order_delivered_customer_date   TIMESTAMP,             -- NULLABLE (not delivered yet)
    order_estimated_delivery_date   TIMESTAMP NOT NULL
);

-- ============================================================================
-- 3. CHILD FULFILLMENT TABLES (COMPOSITE KEYS & FREIGHT)
-- ============================================================================

CREATE TABLE order_items (
    order_id                VARCHAR(50) NOT NULL REFERENCES orders(order_id),
    order_item_id           INT NOT NULL,
    product_id              VARCHAR(50) NOT NULL REFERENCES products(product_id),
    seller_id               VARCHAR(50) NOT NULL REFERENCES sellers(seller_id),
    shipping_limit_date     TIMESTAMP NOT NULL,
    price                   DECIMAL(10, 2) NOT NULL,
    freight_value           DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)                 -- COMPOSITE KEY!
);

CREATE TABLE order_reviews (
    review_id               VARCHAR(50) NOT NULL,
    order_id                VARCHAR(50) NOT NULL REFERENCES orders(order_id),
    review_score            INT NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_creation_date    TIMESTAMP NOT NULL,
    review_answer_timestamp TIMESTAMP NOT NULL
);
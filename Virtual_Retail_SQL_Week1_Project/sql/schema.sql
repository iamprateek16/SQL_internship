-- Virtual Retail Database | MySQL 8.0
-- Run this script in MySQL Workbench. It creates a normalized retail schema.

CREATE DATABASE IF NOT EXISTS virtual_retail
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE virtual_retail;

SET FOREIGN_KEY_CHECKS = 0;
DROP VIEW IF EXISTS vw_order_summary;
DROP TABLE IF EXISTS review;
DROP TABLE IF EXISTS return_item;
DROP TABLE IF EXISTS product_return;
DROP TABLE IF EXISTS shipment;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS order_item;
DROP TABLE IF EXISTS retail_order;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS warehouse;
DROP TABLE IF EXISTS product_supplier;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS supplier;
DROP TABLE IF EXISTS customer_address;
DROP TABLE IF EXISTS customer;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE customer (
    customer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(25),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    customer_status ENUM('ACTIVE','INACTIVE','BLOCKED') NOT NULL DEFAULT 'ACTIVE'
) ENGINE=InnoDB;

CREATE TABLE customer_address (
    address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    address_type ENUM('BILLING','SHIPPING','BOTH') NOT NULL DEFAULT 'SHIPPING',
    line1 VARCHAR(200) NOT NULL,
    line2 VARCHAR(200),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL DEFAULT 'India',
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_address_customer FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id) ON DELETE CASCADE,
    INDEX idx_address_customer (customer_id)
) ENGINE=InnoDB;

CREATE TABLE supplier (
    supplier_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(160) NOT NULL,
    contact_name VARCHAR(120),
    email VARCHAR(255),
    phone VARCHAR(25),
    supplier_status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_supplier_email (email)
) ENGINE=InnoDB;

CREATE TABLE category (
    category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(120) NOT NULL UNIQUE,
    parent_category_id BIGINT UNSIGNED NULL,
    description VARCHAR(500),
    CONSTRAINT fk_category_parent FOREIGN KEY (parent_category_id)
        REFERENCES category(category_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE product (
    product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(64) NOT NULL UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    category_id BIGINT UNSIGNED NOT NULL,
    description TEXT,
    unit_price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_product_price CHECK (unit_price >= 0),
    CONSTRAINT chk_product_cost CHECK (cost_price IS NULL OR cost_price >= 0),
    CONSTRAINT fk_product_category FOREIGN KEY (category_id)
        REFERENCES category(category_id) ON DELETE RESTRICT,
    INDEX idx_product_category (category_id),
    INDEX idx_product_name (product_name)
) ENGINE=InnoDB;

-- A product can be sourced from multiple suppliers; a supplier can supply many products.
CREATE TABLE product_supplier (
    product_id BIGINT UNSIGNED NOT NULL,
    supplier_id BIGINT UNSIGNED NOT NULL,
    supplier_sku VARCHAR(64),
    lead_time_days SMALLINT UNSIGNED,
    purchase_cost DECIMAL(10,2),
    PRIMARY KEY (product_id, supplier_id),
    CONSTRAINT fk_ps_product FOREIGN KEY (product_id)
        REFERENCES product(product_id) ON DELETE CASCADE,
    CONSTRAINT fk_ps_supplier FOREIGN KEY (supplier_id)
        REFERENCES supplier(supplier_id) ON DELETE RESTRICT,
    CONSTRAINT chk_ps_cost CHECK (purchase_cost IS NULL OR purchase_cost >= 0)
) ENGINE=InnoDB;

CREATE TABLE warehouse (
    warehouse_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    warehouse_name VARCHAR(150) NOT NULL,
    address_line VARCHAR(250) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- Inventory is tracked per product and warehouse.
CREATE TABLE inventory (
    warehouse_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    quantity_on_hand INT UNSIGNED NOT NULL DEFAULT 0,
    reorder_level INT UNSIGNED NOT NULL DEFAULT 0,
    last_stock_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (warehouse_id, product_id),
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse(warehouse_id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
        REFERENCES product(product_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE retail_order (
    order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(30) NOT NULL UNIQUE,
    customer_id BIGINT UNSIGNED NOT NULL,
    billing_address_id BIGINT UNSIGNED,
    shipping_address_id BIGINT UNSIGNED,
    order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_status ENUM('PENDING','CONFIRMED','PROCESSING','SHIPPED','DELIVERED','CANCELLED','RETURNED')
        NOT NULL DEFAULT 'PENDING',
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    shipping_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_order_bill_address FOREIGN KEY (billing_address_id)
        REFERENCES customer_address(address_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_ship_address FOREIGN KEY (shipping_address_id)
        REFERENCES customer_address(address_id) ON DELETE SET NULL,
    CONSTRAINT chk_order_amounts CHECK (shipping_fee >= 0 AND tax_amount >= 0 AND discount_amount >= 0),
    INDEX idx_order_customer_date (customer_id, order_date),
    INDEX idx_order_status_date (order_status, order_date)
) ENGINE=InnoDB;

CREATE TABLE order_item (
    order_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    unit_price_at_purchase DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_item_order FOREIGN KEY (order_id)
        REFERENCES retail_order(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_item_product FOREIGN KEY (product_id)
        REFERENCES product(product_id) ON DELETE RESTRICT,
    CONSTRAINT chk_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_item_price CHECK (unit_price_at_purchase >= 0 AND discount_amount >= 0),
    UNIQUE KEY uq_order_product (order_id, product_id),
    INDEX idx_order_item_product (product_id)
) ENGINE=InnoDB;

CREATE TABLE payment (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    payment_reference VARCHAR(100) UNIQUE,
    payment_method ENUM('UPI','CARD','NET_BANKING','COD','WALLET','OTHER') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_status ENUM('INITIATED','AUTHORIZED','PAID','FAILED','REFUNDED') NOT NULL DEFAULT 'INITIATED',
    paid_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id)
        REFERENCES retail_order(order_id) ON DELETE RESTRICT,
    CONSTRAINT chk_payment_amount CHECK (amount >= 0),
    INDEX idx_payment_order_status (order_id, payment_status)
) ENGINE=InnoDB;

CREATE TABLE shipment (
    shipment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    warehouse_id BIGINT UNSIGNED,
    tracking_number VARCHAR(100) UNIQUE,
    carrier VARCHAR(100),
    shipment_status ENUM('READY','IN_TRANSIT','DELIVERED','LOST','RETURN_TO_SENDER')
        NOT NULL DEFAULT 'READY',
    shipped_at DATETIME,
    delivered_at DATETIME,
    CONSTRAINT fk_shipment_order FOREIGN KEY (order_id)
        REFERENCES retail_order(order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_shipment_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse(warehouse_id) ON DELETE SET NULL,
    INDEX idx_shipment_order (order_id),
    INDEX idx_shipment_status (shipment_status)
) ENGINE=InnoDB;

CREATE TABLE product_return (
    return_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    return_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    return_reason VARCHAR(300),
    return_status ENUM('REQUESTED','APPROVED','REJECTED','RECEIVED','REFUNDED')
        NOT NULL DEFAULT 'REQUESTED',
    CONSTRAINT fk_return_order FOREIGN KEY (order_id)
        REFERENCES retail_order(order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_return_customer FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id) ON DELETE RESTRICT,
    INDEX idx_return_order (order_id),
    INDEX idx_return_status_date (return_status, return_date)
) ENGINE=InnoDB;

CREATE TABLE return_item (
    return_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    return_id BIGINT UNSIGNED NOT NULL,
    order_item_id BIGINT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    refund_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_return_item_return FOREIGN KEY (return_id)
        REFERENCES product_return(return_id) ON DELETE CASCADE,
    CONSTRAINT fk_return_item_order_item FOREIGN KEY (order_item_id)
        REFERENCES order_item(order_item_id) ON DELETE RESTRICT,
    CONSTRAINT chk_return_quantity CHECK (quantity > 0),
    CONSTRAINT chk_refund_amount CHECK (refund_amount >= 0),
    INDEX idx_return_item_order_item (order_item_id)
) ENGINE=InnoDB;

CREATE TABLE review (
    review_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    order_id BIGINT UNSIGNED,
    rating TINYINT UNSIGNED NOT NULL,
    review_text VARCHAR(1000),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT fk_review_customer FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_review_product FOREIGN KEY (product_id)
        REFERENCES product(product_id) ON DELETE CASCADE,
    CONSTRAINT fk_review_order FOREIGN KEY (order_id)
        REFERENCES retail_order(order_id) ON DELETE SET NULL,
    UNIQUE KEY uq_customer_product_review (customer_id, product_id),
    INDEX idx_review_product_rating (product_id, rating)
) ENGINE=InnoDB;

-- Reporting view: order totals are calculated from order items, not stored redundantly.
CREATE VIEW vw_order_summary AS
SELECT
    o.order_id,
    o.order_number,
    o.order_date,
    o.order_status,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    COALESCE(items.subtotal, 0) AS item_subtotal,
    o.shipping_fee,
    o.tax_amount,
    o.discount_amount,
    (COALESCE(items.subtotal, 0) + o.shipping_fee + o.tax_amount - o.discount_amount) AS order_total
FROM retail_order o
JOIN customer c ON c.customer_id = o.customer_id
LEFT JOIN (
    SELECT order_id, SUM(quantity * unit_price_at_purchase - discount_amount) AS subtotal
    FROM order_item
    GROUP BY order_id
) items ON items.order_id = o.order_id;

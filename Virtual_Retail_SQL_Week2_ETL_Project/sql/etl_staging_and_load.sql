-- Week 2 ETL Planning Demo | MySQL 8.0
-- Assumes the Week 1 virtual_retail schema already exists.
-- This script demonstrates staging, validation, cleanup, and loading.
-- For production, add batch_id, source_file, row_number, and ETL timestamps to every staging record.

USE virtual_retail;

CREATE TABLE IF NOT EXISTS etl_batch (
    batch_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    source_name VARCHAR(150) NOT NULL,
    started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,
    batch_status ENUM('RUNNING','SUCCESS','FAILED','PARTIAL') NOT NULL DEFAULT 'RUNNING',
    extracted_rows INT UNSIGNED NOT NULL DEFAULT 0,
    loaded_rows INT UNSIGNED NOT NULL DEFAULT 0,
    rejected_rows INT UNSIGNED NOT NULL DEFAULT 0,
    notes VARCHAR(1000)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS etl_reject (
    reject_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    batch_id BIGINT UNSIGNED NOT NULL,
    source_file VARCHAR(255),
    source_row_number INT UNSIGNED,
    entity_name VARCHAR(100) NOT NULL,
    reject_reason VARCHAR(500) NOT NULL,
    raw_record JSON,
    rejected_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reject_batch FOREIGN KEY (batch_id) REFERENCES etl_batch(batch_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS stg_customer (
    stg_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    batch_id BIGINT UNSIGNED NOT NULL,
    customer_code VARCHAR(30),
    first_name VARCHAR(80),
    last_name VARCHAR(80),
    email VARCHAR(255),
    phone VARCHAR(25),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    created_date VARCHAR(30),
    status VARCHAR(30),
    source_row_number INT UNSIGNED,
    processed BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS stg_product_inventory (
    stg_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    batch_id BIGINT UNSIGNED NOT NULL,
    sku VARCHAR(64),
    product_name VARCHAR(200),
    category_name VARCHAR(120),
    description TEXT,
    unit_price_text VARCHAR(30),
    cost_price_text VARCHAR(30),
    supplier_name VARCHAR(160),
    quantity_text VARCHAR(30),
    warehouse_name VARCHAR(150),
    source_row_number INT UNSIGNED,
    processed BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS stg_order_line (
    stg_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    batch_id BIGINT UNSIGNED NOT NULL,
    order_number VARCHAR(30),
    customer_code VARCHAR(30),
    order_date_text VARCHAR(30),
    status_text VARCHAR(30),
    sku VARCHAR(64),
    quantity_text VARCHAR(30),
    unit_price_text VARCHAR(30),
    shipping_fee_text VARCHAR(30),
    tax_amount_text VARCHAR(30),
    discount_amount_text VARCHAR(30),
    payment_method_text VARCHAR(30),
    payment_status_text VARCHAR(30),
    source_row_number INT UNSIGNED,
    processed BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB;

-- Import CSV files into staging tables using Workbench Table Data Import Wizard
-- or LOAD DATA LOCAL INFILE (if enabled and permitted).
-- Example pattern (adjust file path and columns to your machine):
-- LOAD DATA LOCAL INFILE 'C:/path/customers_source.csv'
-- INTO TABLE stg_customer
-- FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 LINES
-- (customer_code, first_name, last_name, email, phone, city, state, postal_code, created_date, status)
-- SET batch_id = 1;

-- 1) Create a batch record before importing. Use its generated ID for staging rows.
INSERT INTO etl_batch (source_name, notes)
VALUES ('Week2 CSV sample files', 'Demo batch for customer, product/inventory, and order source files');
SET @batch_id = LAST_INSERT_ID();

-- 2) After import, normalize customer fields and reject invalid rows.
-- Example: trim strings, lower-case email, map status to allowed values.
INSERT INTO etl_reject (batch_id, source_file, source_row_number, entity_name, reject_reason, raw_record)
SELECT batch_id, 'customers_source.csv', source_row_number, 'customer',
       CASE
         WHEN email IS NULL OR TRIM(email) = '' THEN 'Missing email'
         WHEN LOWER(TRIM(email)) NOT REGEXP '^[A-Z0-9._%+-]+@[A-Z0-9.-]+[.][A-Z]{2,}$' THEN 'Invalid email format'
         WHEN first_name IS NULL OR TRIM(first_name) = '' THEN 'Missing first name'
         ELSE 'Unknown validation failure'
       END,
       JSON_OBJECT('customer_code',customer_code,'first_name',first_name,'last_name',last_name,'email',email)
FROM stg_customer
WHERE batch_id = @batch_id
  AND (email IS NULL OR TRIM(email) = ''
       OR LOWER(TRIM(email)) NOT REGEXP '^[A-Z0-9._%+-]+@[A-Z0-9.-]+[.][A-Z]{2,}$'
       OR first_name IS NULL OR TRIM(first_name) = '');

-- 3) Load valid customers. Duplicate emails are handled with an explicit update policy.
INSERT INTO customer (first_name,last_name,email,phone,customer_status)
SELECT TRIM(first_name), TRIM(last_name), LOWER(TRIM(email)),
       NULLIF(TRIM(phone), ''),
       CASE UPPER(TRIM(status)) WHEN 'ACTIVE' THEN 'ACTIVE'
            WHEN 'INACTIVE' THEN 'INACTIVE' WHEN 'BLOCKED' THEN 'BLOCKED'
            ELSE 'ACTIVE' END
FROM stg_customer s
WHERE s.batch_id = @batch_id
  AND s.email IS NOT NULL
  AND LOWER(TRIM(s.email)) REGEXP '^[A-Z0-9._%+-]+@[A-Z0-9.-]+[.][A-Z]{2,}$'
  AND s.first_name IS NOT NULL AND TRIM(s.first_name) <> ''
ON DUPLICATE KEY UPDATE
    first_name = VALUES(first_name),
    last_name = VALUES(last_name),
    phone = VALUES(phone),
    customer_status = VALUES(customer_status);

-- 4) Category/product load. Create categories first, then products.
INSERT INTO category (category_name)
SELECT DISTINCT TRIM(category_name)
FROM stg_product_inventory
WHERE batch_id = @batch_id AND category_name IS NOT NULL AND TRIM(category_name) <> ''
ON DUPLICATE KEY UPDATE category_name = VALUES(category_name);

INSERT INTO product (sku,product_name,category_id,description,unit_price,cost_price,is_active)
SELECT TRIM(s.sku), TRIM(s.product_name), c.category_id, NULLIF(TRIM(s.description),''),
       CAST(s.unit_price_text AS DECIMAL(10,2)),
       CASE WHEN s.cost_price_text REGEXP '^[0-9]+([.][0-9]+)?$'
            THEN CAST(s.cost_price_text AS DECIMAL(10,2)) ELSE NULL END,
       TRUE
FROM stg_product_inventory s
JOIN category c ON c.category_name = TRIM(s.category_name)
WHERE s.batch_id = @batch_id
  AND s.sku IS NOT NULL AND TRIM(s.sku) <> ''
  AND s.product_name IS NOT NULL AND TRIM(s.product_name) <> ''
  AND s.unit_price_text REGEXP '^[0-9]+([.][0-9]+)?$'
  AND CAST(s.unit_price_text AS DECIMAL(10,2)) >= 0
ON DUPLICATE KEY UPDATE
    product_name = VALUES(product_name),
    category_id = VALUES(category_id),
    description = VALUES(description),
    unit_price = VALUES(unit_price),
    cost_price = VALUES(cost_price),
    is_active = VALUES(is_active);

-- 5) Supplier and warehouse master data must exist before inventory mappings.
INSERT INTO supplier (supplier_name)
SELECT DISTINCT TRIM(supplier_name)
FROM stg_product_inventory
WHERE batch_id = @batch_id AND supplier_name IS NOT NULL AND TRIM(supplier_name) <> ''
ON DUPLICATE KEY UPDATE supplier_name = VALUES(supplier_name);

INSERT INTO warehouse (warehouse_name,address_line,city)
SELECT DISTINCT TRIM(warehouse_name), 'Address pending enrichment', 'Unknown'
FROM stg_product_inventory
WHERE batch_id = @batch_id AND warehouse_name IS NOT NULL AND TRIM(warehouse_name) <> ''
ON DUPLICATE KEY UPDATE warehouse_name = VALUES(warehouse_name);

INSERT INTO product_supplier (product_id,supplier_id,purchase_cost)
SELECT p.product_id,s.supplier_id,
       CASE WHEN st.cost_price_text REGEXP '^[0-9]+([.][0-9]+)?$'
            THEN CAST(st.cost_price_text AS DECIMAL(10,2)) ELSE NULL END
FROM stg_product_inventory st
JOIN product p ON p.sku = TRIM(st.sku)
JOIN supplier s ON s.supplier_name = TRIM(st.supplier_name)
WHERE st.batch_id = @batch_id
ON DUPLICATE KEY UPDATE purchase_cost = VALUES(purchase_cost);

INSERT INTO inventory (warehouse_id,product_id,quantity_on_hand,reorder_level)
SELECT w.warehouse_id,p.product_id,
       CAST(st.quantity_text AS UNSIGNED), 10
FROM stg_product_inventory st
JOIN product p ON p.sku = TRIM(st.sku)
JOIN warehouse w ON w.warehouse_name = TRIM(st.warehouse_name)
WHERE st.batch_id = @batch_id
  AND st.quantity_text REGEXP '^[0-9]+$'
ON DUPLICATE KEY UPDATE quantity_on_hand = VALUES(quantity_on_hand);

-- 6) Order ETL is intentionally shown as a safe planning pattern:
-- Resolve customer and product business keys first; reject missing references.
-- For production, group source rows by order_number, create one retail_order header,
-- then insert order_item rows. Never create duplicate headers for each source line.
-- Do not load cancelled orders or zero/negative quantities as sale line items.
-- Parse dates using STR_TO_DATE with source-specific format rules.

-- Example reject for order lines with missing customer/product references:
INSERT INTO etl_reject (batch_id,source_file,source_row_number,entity_name,reject_reason,raw_record)
SELECT batch_id,'orders_source.csv',source_row_number,'order_line',
       'Customer code or SKU could not be resolved',
       JSON_OBJECT('order_number',order_number,'customer_code',customer_code,'sku',sku)
FROM stg_order_line st
LEFT JOIN customer c ON c.email = st.customer_code -- Replace with a proper source-key mapping table in production.
LEFT JOIN product p ON p.sku = TRIM(st.sku)
WHERE st.batch_id = @batch_id AND (p.product_id IS NULL);

-- 7) Update batch metrics after processing; counts should be computed from actual staging/reject/target rows.
UPDATE etl_batch
SET completed_at = NOW(),
    batch_status = 'PARTIAL',
    notes = CONCAT(COALESCE(notes,''),' Demo run: review reject rows and target counts before marking SUCCESS.')
WHERE batch_id = @batch_id;

-- Operational checks:
SELECT batch_id, source_name, batch_status, extracted_rows, loaded_rows, rejected_rows
FROM etl_batch ORDER BY batch_id DESC;
SELECT entity_name, reject_reason, COUNT(*) AS rejected_count
FROM etl_reject GROUP BY entity_name,reject_reason;

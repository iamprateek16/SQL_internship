-- Week 2 ETL transformation and data quality examples (MySQL 8.0)
USE virtual_retail;

-- A. Normalize whitespace and casing
SELECT LOWER(TRIM(email)) AS standardized_email,
       TRIM(first_name) AS cleaned_first_name
FROM stg_customer;

-- B. Null/blank normalization
SELECT NULLIF(TRIM(phone),'') AS phone_or_null,
       COALESCE(NULLIF(TRIM(city),''),'UNKNOWN') AS city_with_fallback
FROM stg_customer;

-- C. Standardize dates (choose format based on source contract)
SELECT
  CASE
    WHEN order_date_text REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
      THEN STR_TO_DATE(order_date_text,'%Y-%m-%d')
    WHEN order_date_text REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
      THEN STR_TO_DATE(order_date_text,'%m/%d/%Y')
    ELSE NULL
  END AS parsed_order_date
FROM stg_order_line;

-- D. Detect invalid quantities/prices before casting
SELECT *
FROM stg_order_line
WHERE quantity_text NOT REGEXP '^[1-9][0-9]*$'
   OR unit_price_text NOT REGEXP '^[0-9]+([.][0-9]+)?$';

-- E. Duplicate detection by business key
SELECT LOWER(TRIM(email)) AS email_key, COUNT(*) AS row_count
FROM stg_customer
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1;

-- F. Referential integrity check before loading facts
SELECT st.order_number, st.customer_code, st.sku
FROM stg_order_line st
LEFT JOIN product p ON p.sku = TRIM(st.sku)
WHERE p.product_id IS NULL;

-- G. Reconciliation concept: compare extracted count with accepted + rejected count.
-- A production batch should satisfy:
-- extracted_rows = loaded_rows + rejected_rows + intentionally_skipped_rows

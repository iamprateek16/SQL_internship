-- Useful reporting and operational SQL examples
USE virtual_retail;

-- 1. Full order totals
SELECT * FROM vw_order_summary ORDER BY order_date DESC;

-- 2. Products at or below reorder threshold
SELECT p.sku, p.product_name, w.warehouse_name,
       i.quantity_on_hand, i.reorder_level
FROM inventory i
JOIN product p ON p.product_id = i.product_id
JOIN warehouse w ON w.warehouse_id = i.warehouse_id
WHERE i.quantity_on_hand <= i.reorder_level
ORDER BY w.warehouse_name, p.product_name;

-- 3. Best-selling products by units
SELECT p.product_name, SUM(oi.quantity) AS units_sold
FROM order_item oi
JOIN retail_order o ON o.order_id = oi.order_id
JOIN product p ON p.product_id = oi.product_id
WHERE o.order_status NOT IN ('CANCELLED')
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC;

-- 4. Customer lifetime spend (paid/confirmed order states can be refined by policy)
SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS customer_name,
       COUNT(DISTINCT o.order_id) AS order_count,
       SUM(v.order_total) AS lifetime_order_value
FROM customer c
JOIN retail_order o ON o.customer_id = c.customer_id
JOIN vw_order_summary v ON v.order_id = o.order_id
WHERE o.order_status NOT IN ('CANCELLED')
GROUP BY c.customer_id, customer_name
ORDER BY lifetime_order_value DESC;

-- 5. Monthly revenue trend
SELECT DATE_FORMAT(order_date,'%Y-%m') AS sales_month,
       COUNT(*) AS orders,
       SUM(order_total) AS revenue
FROM vw_order_summary
WHERE order_status IN ('CONFIRMED','PROCESSING','SHIPPED','DELIVERED')
GROUP BY DATE_FORMAT(order_date,'%Y-%m')
ORDER BY sales_month;

-- 6. Supplier catalog
SELECT p.sku, p.product_name, s.supplier_name, ps.purchase_cost, ps.lead_time_days
FROM product_supplier ps
JOIN product p ON p.product_id = ps.product_id
JOIN supplier s ON s.supplier_id = ps.supplier_id
ORDER BY p.product_name, s.supplier_name;

-- 7. Customer order history
SELECT o.order_number, o.order_date, o.order_status, v.order_total
FROM retail_order o
JOIN vw_order_summary v ON v.order_id = o.order_id
WHERE o.customer_id = 1
ORDER BY o.order_date DESC;

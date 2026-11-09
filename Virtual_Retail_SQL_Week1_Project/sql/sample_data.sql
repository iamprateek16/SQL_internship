-- Optional demo data. Run after schema.sql.
USE virtual_retail;

INSERT INTO customer (first_name,last_name,email,phone) VALUES
('Aarav','Shah','aarav.shah@example.com','9000000001'),
('Meera','Patil','meera.patil@example.com','9000000002');

INSERT INTO customer_address (customer_id,address_type,line1,city,state,postal_code,is_default) VALUES
(1,'BOTH','12 Palm Avenue','Mumbai','Maharashtra','400001',TRUE),
(2,'BOTH','8 Lake Road','Pune','Maharashtra','411001',TRUE);

INSERT INTO supplier (supplier_name,contact_name,email,phone) VALUES
('TechSource India','Rohan Desai','sales@techsource.example','02240000001'),
('Everyday Retail Supply','Kavya Rao','contact@everyday.example','02040000002');

INSERT INTO category (category_name,description) VALUES
('Electronics','Electronic devices and accessories'),
('Home & Living','Home essentials');

INSERT INTO product (sku,product_name,category_id,description,unit_price,cost_price) VALUES
('EL-1001','Wireless Mouse',1,'Wireless optical mouse',799.00,450.00),
('EL-1002','USB-C Charger',1,'30W USB-C charger',1299.00,800.00),
('HL-2001','Desk Lamp',2,'LED desk lamp',999.00,600.00);

INSERT INTO product_supplier (product_id,supplier_id,supplier_sku,lead_time_days,purchase_cost) VALUES
(1,1,'TS-MOUSE-01',4,450.00),
(2,1,'TS-CHARGER-02',5,800.00),
(3,2,'ERS-LAMP-10',3,600.00);

INSERT INTO warehouse (warehouse_name,address_line,city,state,postal_code) VALUES
('Mumbai Central Warehouse','Plot 10, MIDC','Mumbai','Maharashtra','400093'),
('Pune Fulfilment Hub','Unit 4, Industrial Area','Pune','Maharashtra','411019');

INSERT INTO inventory (warehouse_id,product_id,quantity_on_hand,reorder_level) VALUES
(1,1,120,20),(1,2,60,15),(1,3,40,10),
(2,1,50,10),(2,2,25,8),(2,3,70,12);

INSERT INTO retail_order (order_number,customer_id,billing_address_id,shipping_address_id,order_status,shipping_fee,tax_amount,discount_amount) VALUES
('VR-2026-0001',1,1,1,'CONFIRMED',50.00,90.00,100.00),
('VR-2026-0002',2,2,2,'PROCESSING',0.00,117.00,0.00);

INSERT INTO order_item (order_id,product_id,quantity,unit_price_at_purchase,discount_amount) VALUES
(1,1,2,799.00,50.00),(1,3,1,999.00,0.00),
(2,2,1,1299.00,0.00);

INSERT INTO payment (order_id,payment_reference,payment_method,amount,payment_status,paid_at) VALUES
(1,'PAY-DEMO-0001','UPI',2587.00,'PAID',NOW()),
(2,'PAY-DEMO-0002','CARD',1416.00,'AUTHORIZED',NULL);

INSERT INTO shipment (order_id,warehouse_id,tracking_number,carrier,shipment_status) VALUES
(1,1,'TRACK-DEMO-0001','Demo Logistics','READY');

INSERT INTO review (customer_id,product_id,order_id,rating,review_text) VALUES
(1,1,1,5,'Works well and setup was easy.');

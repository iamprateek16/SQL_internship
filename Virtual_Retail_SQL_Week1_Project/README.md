# Virtual Retail Database (Week 1 — SQL Developer Internship)

A normalized relational database design for a virtual retail business using **MySQL 8.0**.

## Contents
- `sql/schema.sql` — database and table creation scripts
- `sql/sample_data.sql` — optional demo records
- `sql/queries.sql` — example operational and reporting queries
- `docs/retail_erd.png` — simplified logical ER diagram
- `docs/architecture.png` — three-tier architecture diagram
- `Week1_Data_Modeling_Architecture_Report.docx` — internship report

## Business scope
The model supports customer management, product catalog, supplier sourcing, warehouse inventory, order processing, payments, shipments, returns, and product reviews.

## Setup
1. Install MySQL Server 8.0 and MySQL Workbench.
2. Open `sql/schema.sql` in Workbench and execute it.
3. Execute `sql/sample_data.sql` to add sample records.
4. Execute `sql/queries.sql` to test the reporting queries.
5. Inspect the `vw_order_summary` view.

## Suggested GitHub repository
Repository name: `virtual-retail-database`
Description: `Normalized MySQL database design for a virtual retail platform, including ERD, architecture, sample data, and reporting queries.`

## Design notes
- InnoDB is used for transactions and foreign-key enforcement.
- Monetary values use `DECIMAL`, not floating-point types.
- Order item prices are snapshots, preserving historical purchase prices if catalog prices change.
- Inventory is tracked per warehouse and product.
- Product-supplier relationships are many-to-many and use a composite primary key.
- Order totals are derived in a view to avoid storing a redundant calculated total.
- Foreign keys and CHECK constraints help preserve data integrity.
- Indexes target common lookups, joins, status filters, and reporting dimensions.

## Important
This is a learning/demo design. A production system should additionally implement authentication, authorization, stock reservation and release logic, payment gateway integration, audit trails, tax rules, privacy controls, backups, monitoring, and tested migration procedures. Do not use the demo customer or payment data in production.

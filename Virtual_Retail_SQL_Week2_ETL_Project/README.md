# Virtual Retail ETL Plan — Week 2

## Deliverables
- `Week2_ETL_Planning_Report.docx` — detailed report
- `docs/etl_flowchart.png` — ETL pipeline flowchart
- `sql/etl_staging_and_load.sql` — MySQL staging and ETL example
- `sql/data_quality_examples.sql` — validation/cleaning examples
- `data/` — small sample source CSVs with deliberate data-quality cases
- `submission_description.txt` — 200+ word portal description

## Relationship to Week 1
This ETL plan targets the normalized `virtual_retail` MySQL database created in Week 1. Run the Week 1 schema first. The Week 2 script creates ETL batch, reject-log, and staging tables.

## Suggested workflow
1. Create the Week 1 database schema.
2. Create ETL control and staging tables using `sql/etl_staging_and_load.sql`.
3. Import source CSV files into staging tables using MySQL Workbench's Table Data Import Wizard (or a configured `LOAD DATA LOCAL INFILE`).
4. Review validation queries in `sql/data_quality_examples.sql`.
5. Execute transformation/load sections only after reviewing staging records and batch ID.
6. Review rejected records and reconcile batch counts.
7. Run Week 1 operational queries to validate the target database.

## Notes
The files are an internship planning/demo implementation, not a production ETL job. The order-loading section is intentionally a design pattern rather than a complete executable order loader because source customer identifiers require a source-to-target mapping table and order headers must be grouped by order number. Review and adapt the SQL to your local source format before running it.

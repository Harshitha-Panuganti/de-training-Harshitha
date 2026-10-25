
SELECT 'dim_date' AS table_name, COUNT(*) AS row_count
FROM mart.dim_date

UNION ALL

SELECT 'dim_product', COUNT(*)
FROM mart.dim_product

UNION ALL

SELECT 'dim_customer', COUNT(*)
FROM mart.dim_customer;

USE AdventureWorksLT2022;
GO
SELECT
    (SELECT COUNT(*)
     FROM SalesLT.SalesOrderDetail) AS source_sales_lines,
    (SELECT COUNT(*)
     FROM mart.fact_sales) AS mart_sales_rows,
    (SELECT SUM(SubTotal)
     FROM SalesLT.SalesOrderHeader) AS source_revenue,
    (SELECT SUM(revenue)
     FROM mart.fact_sales) AS mart_revenue;

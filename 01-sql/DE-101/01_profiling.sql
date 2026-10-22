--1
USE AdventureWorksLT2022;
GO
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT CustomerID) AS customers_with_orders,
    MIN(OrderDate) AS first_order,
    MAX(OrderDate) AS last_order,
    SUM(CASE WHEN ShipDate IS NULL
             THEN 1 ELSE 0 END) AS not_shipped,
    SUM(CASE WHEN OrderDate IS NULL
             THEN 1 ELSE 0 END) AS missing_order_dates,
    SUM(CASE WHEN CustomerID IS NULL
             THEN 1 ELSE 0 END) AS missing_customer_ids
FROM SalesLT.SalesOrderHeader;


-- 2

SELECT
    COUNT(*) AS total_order_lines,
    SUM(CASE WHEN OrderQty = 0 THEN 1 ELSE 0 END)
        AS zero_quantities,
    SUM(CASE WHEN OrderQty < 0 THEN 1 ELSE 0 END)
        AS negative_quantities,
    SUM(CASE WHEN UnitPrice = 0 THEN 1 ELSE 0 END)
        AS zero_prices,
    SUM(CASE WHEN UnitPrice < 0 THEN 1 ELSE 0 END)
        AS negative_prices,
    SUM(CASE WHEN LineTotal IS NULL THEN 1 ELSE 0 END)
        AS missing_line_totals,
    SUM(LineTotal) AS total_line_revenue
FROM SalesLT.SalesOrderDetail;

--3 

SELECT
    OrderDate,
    COUNT(*) AS NumberOfOrders
FROM SalesLT.SalesOrderHeader
GROUP BY OrderDate
ORDER BY OrderDate;

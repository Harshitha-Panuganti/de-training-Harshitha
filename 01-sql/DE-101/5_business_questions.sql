
INSERT INTO mart.fact_sales
(
    sales_order_detail_id,
    sales_order_id,
    customer_key,
    product_key,
    date_key,
    quantity,
    unit_price,
    discount_rate,
    revenue
)
SELECT
    d.SalesOrderDetailID,
    h.SalesOrderID,
    dc.customer_key,
    dp.product_key,
    dd.date_key,
    d.OrderQty,
    d.UnitPrice,
    d.UnitPriceDiscount,
    d.LineTotal
FROM SalesLT.SalesOrderDetail AS d
INNER JOIN SalesLT.SalesOrderHeader AS h
    ON d.SalesOrderID = h.SalesOrderID
INNER JOIN mart.dim_customer AS dc
    ON h.CustomerID = dc.customer_id
   AND dc.is_current = 1
INNER JOIN mart.dim_product AS dp
    ON d.ProductID = dp.product_id
INNER JOIN mart.dim_date AS dd
    ON CAST(h.OrderDate AS DATE) = dd.full_date
WHERE NOT EXISTS
(
    SELECT 1
    FROM mart.fact_sales AS existing
    WHERE existing.sales_order_detail_id = d.SalesOrderDetailID
);



SELECT
    COUNT(*) AS mart_sales_rows,
    SUM(revenue) AS mart_revenue
FROM mart.fact_sales;



SELECT
    (SELECT SUM(SubTotal)
     FROM SalesLT.SalesOrderHeader) AS source_subtotal,
    (SELECT SUM(LineTotal)
     FROM SalesLT.SalesOrderDetail) AS source_line_revenue,
    (SELECT SUM(revenue)
     FROM mart.fact_sales) AS mart_revenue;

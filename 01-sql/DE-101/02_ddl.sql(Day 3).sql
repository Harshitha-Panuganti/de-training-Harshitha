
USE AdventureWorksLT2022;
GO

-- 1. Calendar dimension
IF OBJECT_ID(N'mart.dim_date', N'U') IS NULL
BEGIN
    CREATE TABLE mart.dim_date
    (
        date_key   INT          NOT NULL PRIMARY KEY,
        full_date  DATE         NOT NULL UNIQUE,
        [day]      TINYINT      NOT NULL,
        [month]    TINYINT      NOT NULL,
        month_name NVARCHAR(20) NOT NULL,
        [quarter]  TINYINT      NOT NULL,
        [year]     SMALLINT     NOT NULL
    );
END;
GO

-- 2. Product dimension
IF OBJECT_ID(N'mart.dim_product', N'U') IS NULL
BEGIN
    CREATE TABLE mart.dim_product
    (
        product_key       INT IDENTITY(1,1) PRIMARY KEY,
        product_id        INT           NOT NULL UNIQUE,
        product_name      NVARCHAR(100) NOT NULL,
        product_number    NVARCHAR(25)  NOT NULL,
        subcategory_id    INT           NULL,
        subcategory_name  NVARCHAR(100) NULL,
        category_id       INT           NULL,
        category_name     NVARCHAR(100) NULL
    );
END;
GO

-- 3. Customer dimension with SCD Type 2 history
IF OBJECT_ID(N'mart.dim_customer', N'U') IS NULL
BEGIN
    CREATE TABLE mart.dim_customer
    (
        customer_key INT IDENTITY(1,1) PRIMARY KEY,
        customer_id  INT           NOT NULL,
        first_name   NVARCHAR(50)  NULL,
        last_name    NVARCHAR(50)  NULL,
        company_name NVARCHAR(128) NULL,
        city         NVARCHAR(60)  NULL,
        country      NVARCHAR(60)  NULL,
        valid_from   DATETIME2     NOT NULL,
        valid_to     DATETIME2     NOT NULL
            DEFAULT ('9999-12-31 23:59:59.9999999'),
        is_current   BIT           NOT NULL
    );
END;
GO

-- 4. Sales fact table: one row per sales-order line
IF OBJECT_ID(N'mart.fact_sales', N'U') IS NULL
BEGIN
    CREATE TABLE mart.fact_sales
    (
        sales_order_detail_id INT           NOT NULL PRIMARY KEY,
        sales_order_id        INT           NOT NULL,
        customer_key          INT           NOT NULL,
        product_key           INT           NOT NULL,
        date_key              INT           NOT NULL,
        quantity              SMALLINT      NOT NULL,
        unit_price            DECIMAL(19,4) NOT NULL,
        discount_rate         DECIMAL(9,6)  NOT NULL,
        revenue               DECIMAL(19,4) NOT NULL,

        CONSTRAINT FK_fact_sales_customer
            FOREIGN KEY (customer_key)
            REFERENCES mart.dim_customer(customer_key),

        CONSTRAINT FK_fact_sales_product
            FOREIGN KEY (product_key)
            REFERENCES mart.dim_product(product_key),

        CONSTRAINT FK_fact_sales_date
            FOREIGN KEY (date_key)
            REFERENCES mart.dim_date(date_key)
    );
END;
GO

-- 5. Load log
IF OBJECT_ID(N'mart.load_log', N'U') IS NULL
BEGIN
    CREATE TABLE mart.load_log
    (
        log_id        INT IDENTITY(1,1) PRIMARY KEY,
        start_time    DATETIME2    NOT NULL,
        end_time      DATETIME2    NULL,
        rows_loaded   INT          NULL,
        status        VARCHAR(20)  NOT NULL,
        error_message NVARCHAR(MAX) NULL
    );
END;
GO

IF OBJECT_ID(N'mart.dim_date', N'U') IS NULL

-- 1
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'mart'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- 2
INSERT INTO mart.dim_date
(
    date_key,
    full_date,
    [day],
    [month],
    month_name,
    [quarter],
    [year]
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), d.full_date, 112)) AS date_key,
    d.full_date,
    DAY(d.full_date) AS [day],
    MONTH(d.full_date) AS [month],
    DATENAME(MONTH, d.full_date) AS month_name,
    DATEPART(QUARTER, d.full_date) AS [quarter],
    YEAR(d.full_date) AS [year]
FROM
(
    SELECT DISTINCT CAST(OrderDate AS DATE) AS full_date
    FROM SalesLT.SalesOrderHeader
) AS d
WHERE NOT EXISTS
(
    SELECT 1
    FROM mart.dim_date AS existing
    WHERE existing.full_date = d.full_date
);


SELECT *
FROM mart.dim_date
ORDER BY full_date;



INSERT INTO mart.dim_product
(
    product_id,
    product_name,
    product_number,
    subcategory_id,
    subcategory_name,
    category_id,
    category_name
)
SELECT
    p.ProductID,
    p.Name,
    p.ProductNumber,
    sub.ProductCategoryID,
    sub.Name,
    parent.ProductCategoryID,
    parent.Name
FROM SalesLT.Product AS p
LEFT JOIN SalesLT.ProductCategory AS sub
    ON p.ProductCategoryID = sub.ProductCategoryID
LEFT JOIN SalesLT.ProductCategory AS parent
    ON sub.ParentProductCategoryID = parent.ProductCategoryID
WHERE NOT EXISTS
(
    SELECT 1
    FROM mart.dim_product AS existing
    WHERE existing.product_id = p.ProductID
);



SELECT
    AddressType,
    COUNT(*) AS total_records
FROM SalesLT.CustomerAddress
GROUP BY AddressType
ORDER BY AddressType;


-- 4

INSERT INTO mart.dim_customer
(
    customer_id,
    first_name,
    last_name,
    company_name,
    city,
    country,
    valid_from,
    valid_to,
    is_current
)
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.CompanyName,
    a.City,
    a.CountryRegion,
    CAST('1900-01-01' AS DATETIME2),
    CAST('9999-12-31 23:59:59.9999999' AS DATETIME2),
    1
FROM SalesLT.Customer AS c
OUTER APPLY
(
    SELECT TOP (1)
        addr.City,
        addr.CountryRegion
    FROM SalesLT.CustomerAddress AS ca
    INNER JOIN SalesLT.Address AS addr
        ON ca.AddressID = addr.AddressID
    WHERE ca.CustomerID = c.CustomerID
    ORDER BY
        CASE WHEN ca.AddressType = 'Main Office' THEN 0 ELSE 1 END,
        ca.AddressID
) AS a
WHERE NOT EXISTS
(
    SELECT 1
    FROM mart.dim_customer AS existing
    WHERE existing.customer_id = c.CustomerID
      AND existing.is_current = 1
);

SELECT COUNT(*) AS total_customer_versions
FROM mart.dim_customer;

SELECT COUNT(*) AS current_customers
FROM mart.dim_customer
WHERE is_current = 1;

SELECT TOP 10 *
FROM mart.dim_customer
ORDER BY customer_id;



SELECT
    customer_id,
    COUNT(*) AS total_versions,
    SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END) AS current_versions
FROM mart.dim_customer
GROUP BY customer_id
HAVING SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END) <> 1;

SELECT
    COUNT(*) AS total_versions,
    SUM(CASE WHEN is_current = 1 THEN 1 ELSE 0 END) AS current_customers
FROM mart.dim_customer;
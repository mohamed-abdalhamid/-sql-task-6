

-- 1. Customer Spending Analysis
---------------------------------------------------
DECLARE @CustomerID INT = 1;
DECLARE @TotalSpent MONEY;

SELECT @TotalSpent = SUM(total_due)
FROM sales_orders
WHERE customer_id = @CustomerID;

IF @TotalSpent > 5000
    PRINT 'Customer is a VIP (Spent: $' + CAST(@TotalSpent AS VARCHAR) + ')';
ELSE
    PRINT 'Customer is Regular (Spent: $' + CAST(@TotalSpent AS VARCHAR) + ')';

 ---------------------------------------------------
-- 2. Product Price Threshold Report

DECLARE @Threshold MONEY = 1500;
DECLARE @ProductCount INT;

SELECT @ProductCount = COUNT(*)
FROM products
WHERE list_price > @Threshold;

PRINT 'Threshold Price: $' + CAST(@Threshold AS VARCHAR);
PRINT 'Number of Products Above Threshold: ' + CAST(@ProductCount AS VARCHAR);

---------------------------------------------------
-- 3. Staff Performance Calculator

DECLARE @StaffID INT = 2;
DECLARE @Year INT = 2017;
DECLARE @TotalSales MONEY;

SELECT @TotalSales = SUM(total_due)
FROM sales_orders
WHERE staff_id = @StaffID AND YEAR(order_date) = @Year;

PRINT 'Staff ID: ' + CAST(@StaffID AS VARCHAR) +
      ', Year: ' + CAST(@Year AS VARCHAR) +
      ', Total Sales: $' + CAST(@TotalSales AS VARCHAR);

---------------------------------------------------
-- 4. Global Variables Information

SELECT 
    @@SERVERNAME AS ServerName,
    @@VERSION AS SQLVersion,
    @@ROWCOUNT AS LastRowsAffected;

 ---------------------------------------------------
-- 5. Inventory Level Check

DECLARE @Quantity INT;

SELECT @Quantity = quantity
FROM stocks
WHERE product_id = 1 AND store_id = 1;

IF @Quantity > 20
    PRINT 'Well stocked';
ELSE IF @Quantity BETWEEN 10 AND 20
    PRINT 'Moderate stock';
ELSE
    PRINT 'Low stock - reorder needed';

---------------------------------------------------
-- 6. WHILE Loop for Low-Stock Update

DECLARE @BatchSize INT = 3;
WHILE EXISTS (SELECT TOP 1 * FROM stocks WHERE quantity < 5)
BEGIN
    UPDATE TOP (@BatchSize) stocks
    SET quantity = quantity + 10
    WHERE quantity < 5;

    PRINT 'Batch updated with +10 units';
END

---------------------------------------------------
-- 7. Product Price Categorization

SELECT product_id, name, list_price,
    CASE 
        WHEN list_price < 300 THEN 'Budget'
        WHEN list_price BETWEEN 300 AND 800 THEN 'Mid-Range'
        WHEN list_price BETWEEN 801 AND 2000 THEN 'Premium'
        ELSE 'Luxury'
    END AS PriceCategory
FROM products;

---------------------------------------------------
-- 8. Customer Order Validation

IF EXISTS (SELECT * FROM customers WHERE customer_id = 5)
BEGIN
    SELECT COUNT(*) AS OrderCount
    FROM sales_orders
    WHERE customer_id = 5;
END
ELSE
    PRINT 'Customer ID 5 does not exist.';

---------------------------------------------------
-- 9. Shipping Cost Calculator Function

CREATE FUNCTION CalculateShipping (@Total MONEY)
RETURNS MONEY
AS
BEGIN
    RETURN CASE 
        WHEN @Total > 100 THEN 0
        WHEN @Total BETWEEN 50 AND 99.99 THEN 5.99
        ELSE 12.99
    END
END;

---------------------------------------------------
-- 10. Product Category Function

CREATE FUNCTION GetProductsByPriceRange (@Min MONEY, @Max MONEY)
RETURNS TABLE
AS
RETURN
    SELECT p.product_id, p.name, p.list_price, b.brand_name, c.category_name
    FROM products p
    JOIN brands b ON p.brand_id = b.brand_id
    JOIN categories c ON p.category_id = c.category_id
    WHERE p.list_price BETWEEN @Min AND @Max;

---------------------------------------------------
-- 11. Customer Sales Summary Function

CREATE FUNCTION GetCustomerYearlySummary (@CustomerID INT)
RETURNS @Summary TABLE (
    Year INT,
    TotalOrders INT,
    TotalSpent MONEY,
    AvgOrderValue MONEY
)
AS
BEGIN
    INSERT INTO @Summary
    SELECT 
        YEAR(order_date) AS Year,
        COUNT(*) AS TotalOrders,
        SUM(total_due) AS TotalSpent,
        AVG(total_due) AS AvgOrderValue
    FROM sales_orders
    WHERE customer_id = @CustomerID
    GROUP BY YEAR(order_date);

    RETURN;
END;

---------------------------------------------------
-- 12. Discount Calculation Function

CREATE FUNCTION CalculateBulkDiscount (@Qty INT)
RETURNS INT
AS
BEGIN
    RETURN CASE
        WHEN @Qty BETWEEN 1 AND 2 THEN 0
        WHEN @Qty BETWEEN 3 AND 5 THEN 5
        WHEN @Qty BETWEEN 6 AND 9 THEN 10
        ELSE 15
    END;
END;


-- 13. Customer Order History Procedure

CREATE PROCEDURE sp_GetCustomerOrderHistory 
    @CustomerID INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SELECT order_id, order_date, total_due
    FROM sales_orders
    WHERE customer_id = @CustomerID
    AND (@StartDate IS NULL OR order_date >= @StartDate)
    AND (@EndDate IS NULL OR order_date <= @EndDate);
END;

---------------------------------------------------
-- 14. Inventory Restock Procedure

CREATE PROCEDURE sp_RestockProduct 
    @StoreID INT,
    @ProductID INT,
    @RestockQty INT,
    @OldQty INT OUTPUT,
    @NewQty INT OUTPUT,
    @Success BIT OUTPUT
AS
BEGIN
    BEGIN TRY
        SELECT @OldQty = quantity
        FROM stocks
        WHERE store_id = @StoreID AND product_id = @ProductID;

        UPDATE stocks
        SET quantity = quantity + @RestockQty
        WHERE store_id = @StoreID AND product_id = @ProductID;

        SELECT @NewQty = quantity
        FROM stocks
        WHERE store_id = @StoreID AND product_id = @ProductID;

        SET @Success = 1;
    END TRY
    BEGIN CATCH
        SET @Success = 0;
    END CATCH
END;

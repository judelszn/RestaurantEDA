-- Create Restaurant database
CREATE DATABASE Restaurant;

-- Tables inputed from csv files

-- Initiate use of database
USE Restaurant;

-- View OrderDetails table
SELECT *
FROM dbo.OrderDetails;

-- Make copy OrderDetails table structure into new table OrderDetailse
-- OrderDetails table contains Null values for ItemID. Maybe no item was ordered
SELECT * 
INTO dbo.OrderDetailse
FROM dbo.OrderDetails
WHERE 1 = 0;

-- View OrderDetailse table - a copy of OrderDetails table
SELECT *
FROM dbo.OrderDetailse;

-- Copy data into OrderDetailse table without Null values in ItemID
INSERT dbo.OrderDetailse
SELECT *
FROM DBO.OrderDetails OD
WHERE OD.ItemID IS NOT NULL;

-- Check if Null values in ItemID column
SELECT DISTINCT O.ItemID
FROM dbo.OrderDetailse O;

-- Check details of database
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS;

-- Change datatype of ItemID column
ALTER TABLE OrderDetailse
ALTER COLUMN ItemID INT;

-- View MenuItems Table
SELECT *
FROM dbo.MenuItems;

-- Add primary key to MenuItems table
ALTER TABLE MenuItems
ADD PRIMARY KEY (MenuItemID);

-- Add primary key to OrderDetailse table
ALTER TABLE OrderDetailse
ADD PRIMARY KEY (OrderDetailsID);

-- Add foreign key to OrderDetailse table
ALTER TABLE OrderDetailse
ADD FOREIGN KEY (ItemID)
REFERENCES MenuItems (MenuItemID);

-- Drop OrderDetails table - intial table
DROP TABLE OrderDetails;

-- Rename OrderDetailse table (copy of intial table) to OrderDetails (cleaned table)
EXEC sp_rename 'dbo.OrderDetailse', 'OrderDetails'

-- Partition OrderDetails table (cleaned table)
SELECT *
	, ROW_NUMBER() OVER(
		PARTITION BY OrderDetailsID, OrderID, OrderDate, OrderTime, ItemID 
		ORDER BY OrderDetailsID
		) AS RowNumber
FROM dbo.OrderDetails;

-- Check for duplicates
WITH DuplicateCTE AS (
	SELECT *
	, ROW_NUMBER() OVER(
		PARTITION BY OrderDetailsID, OrderID, OrderDate, OrderTime, ItemID 
		ORDER BY OrderDetailsID
		) AS RowNumber
	FROM dbo.OrderDetails
	)
SELECT *
FROM DuplicateCTE
WHERE RowNumber > 1
;



-- View the MenuItems Table
SELECT *
FROM dbo.MenuItems
;


-- Number of Items on the menu
SELECT COUNT(DISTINCT M.MenuItemID) AS ItemCount
FROM dbo.MenuItems M
;


-- What are the least and most expensive items on the menu?
-- Most expensive
SELECT *
FROM dbo.MenuItems M
ORDER BY M.Price DESC
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY
;

-- Least expensive
SELECT *
FROM dbo.MenuItems M
ORDER BY M.Price ASC
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY
;


-- How many Italian dishes are on the menu?
SELECT COUNT(*) AS ItalianDishesCount
FROM dbo.MenuItems M
WHERE M.Category LIKE 'Ital%'
;


-- What are the least and most expensive Italian dishes on the menu?
-- Most expensive
SELECT *
FROM dbo.MenuItems M
WHERE M.Category LIKE 'Ital%'
ORDER BY M.Price DESC
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY
;

-- Least expensive
SELECT *
FROM dbo.MenuItems M
WHERE M.Category LIKE 'Ital%'
ORDER BY M.Price ASC
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY
;


-- How many dishes are in each category?
SELECT M.Category 
	, COUNT(M.MenuItemID) AS ItemCountPerCategory
FROM dbo.MenuItems M
GROUP BY M.Category
ORDER BY COUNT(M.MenuItemID) DESC
;


-- What is the average dish price with each category?
SELECT M.Category 
	, ROUND(AVG(M.Price), 2) AS AveragePrice
FROM dbo.MenuItems M
GROUP BY M.Category
ORDER BY ROUND(AVG(M.Price), 2) DESC
;


-- View the OrderDetails table
SELECT *
FROM dbo.OrderDetails
;


-- What is the date range of the table?
SELECT MIN(O.OrderDate) AS MinimunDate
	, MAX(O.OrderDate) AS MaximumDate
FROM dbo.OrderDetails O
;


-- How many orders were made within this date range?
SELECT COUNT(DISTINCT O.OrderID) AS TotalOrders
FROM dbo.OrderDetails O
;


-- How many items were ordered within this date range?
SELECT COUNT(*) AS TotalItemsOrdered
FROM dbo.OrderDetails O
;


-- Which orders had the most number of items?
SELECT O.OrderID
	, COUNT(O.ItemID) AS ItemPerOrderCount
FROM dbo.OrderDetails O
GROUP BY O.OrderID
ORDER BY COUNT(O.ItemID) DESC
;


-- How many orders had more than 12 items? 
WITH NumberOfOrders AS (
	SELECT O.OrderID
		, COUNT(O.ItemID) AS ItemPerOrderCount
	FROM dbo.OrderDetails O
	GROUP BY O.OrderID
	HAVING COUNT(O.ItemID) > 12
	)
SELECT COUNT(*) AS Above12ItemsOrderCount
FROM NumberOfOrders
;


-- Combine MenuItems table and OrderDetails table
SELECT *
FROM dbo.OrderDetails O
LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
;


-- What were the least and most ordered items? What categories were they in? 
-- Most ordered item
SELECT M.ItemName
	, M.Category
	, COUNT(O.OrderDetailsID) OrdersCount
FROM dbo.OrderDetails O
LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
GROUP BY M.ItemName, M.Category
ORDER BY COUNT(O.OrderDetailsID) DESC
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY
;

-- Least ordered item
SELECT M.ItemName
	, M.Category
	, COUNT(O.OrderDetailsID) OrdersCount
FROM dbo.OrderDetails O
LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
GROUP BY M.ItemName, M.Category 
ORDER BY COUNT(O.OrderDetailsID) ASC
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY
;


-- What were the top 5 orders that spent the most money on?
SELECT TOP 5 O.OrderID
	, ROUND(SUM(M.Price), 2) MoneySpent
FROM dbo.OrderDetails O
LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
GROUP BY O.OrderID
ORDER BY SUM(M.Price) DESC
;


-- View the details of highest spent order. What insights can you gather from the table
WITH TotalSpent AS (
	SELECT TOP 1 O.OrderID
		, ROUND(SUM(M.Price), 2) MoneySpent
	FROM dbo.OrderDetails O
	LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
	GROUP BY O.OrderID
	ORDER BY SUM(M.Price) DESC
	)
SELECT *
FROM TotalSpent TS
INNER JOIN dbo.OrderDetails O ON TS.OrderID = O.OrderID
LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
;

-- OR
SELECT *
FROM dbo.OrderDetails O
LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
WHERE O.OrderID = 440
;

-- OR 
SELECT *
FROM dbo.OrderDetails O
LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
WHERE O.OrderID IN (
					SELECT TOP 1 O.OrderID
					FROM dbo.OrderDetails O
					LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
					GROUP BY O.OrderID
					ORDER BY SUM(M.Price) DESC
					)
;

-- Insight
SELECT M.Category
	, COUNT(O.ItemID) AS ItemCount
FROM dbo.OrderDetails O
LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
WHERE O.OrderID = 440
GROUP BY M.Category
ORDER BY COUNT(O.ItemID) DESC
;


-- -- View the details of top 5 highest spent order. What insights can you gather from the table
SELECT M.Category
	, COUNT(O.ItemID) AS ItemCount
FROM dbo.OrderDetails O
LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
WHERE O.OrderID IN (
					SELECT TOP 5 O.OrderID
					FROM dbo.OrderDetails O
					LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
					GROUP BY O.OrderID
					ORDER BY SUM(M.Price) DESC
					)
GROUP BY M.Category
ORDER BY COUNT(O.ItemID) DESC
;

-- For each order
SELECT O.OrderID
	, M.Category
	, COUNT(O.ItemID) AS ItemCount
FROM dbo.OrderDetails O
LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
WHERE O.OrderID IN (
					SELECT TOP 5 O.OrderID
					FROM dbo.OrderDetails O
					LEFT JOIN dbo.MenuItems M ON O.ItemID = M.MenuItemID
					GROUP BY O.OrderID
					ORDER BY SUM(M.Price) DESC
					)
GROUP BY O.OrderID, M.Category
ORDER BY COUNT(O.ItemID) DESC
;
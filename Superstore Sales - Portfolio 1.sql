------------------------------------------------ INTRODUCTION -----------------------------------------------
--
-- In this project, we will try using queries to answer some questions regarding data exploration on the
-- Superstore Sales dataset.
--
-- Use the Superstore Sales database
USE SuperstoreSales;
SELECT *
FROM Superstore_Sales;
--
-- After looking and analyzing the data contained in the Superstore Sales dataset, there are some critical
-- questions we can ask in order to gather some important insights that can be beneficial to the business 
-- executives.
-- 
-------------------------------------------- UNIVARIATE ANALYSIS --------------------------------------------
--
-- A. PRODUCT SHIPMENT:
-- 1. What is the average order processing time for each Ship Mode?
SELECT 
	[Ship Mode],
	ROUND(AVG(CAST([Ship Date] AS FLOAT) - CAST([Order Date] AS FLOAT)), 2) AS [Average Shipping Time (Days)]
FROM Superstore_Sales
GROUP BY [Ship Mode]
ORDER BY [Average Shipping Time (Days)];
-- 2. How is the shipment distributed?
SELECT
	[Ship Mode],
	COUNT([Ship Mode]) AS [Count],
	ROUND(CAST(COUNT([Ship Mode]) AS FLOAT) * 100 / CAST((SELECT COUNT([Ship Mode]) FROM Superstore_Sales) 
		AS FLOAT), 2) AS [Count Percentage (%)]
FROM Superstore_Sales
GROUP BY [Ship Mode]
ORDER BY Count DESC;
--
-- B. CUSTOMER SEGMENT:
-- 1. What is the percentage of sales for each customer Segment?
SELECT 
	Segment,
	SUM(Sales) AS [Sales ($)],
	ROUND(SUM(Sales) * 100 / (SELECT SUM(Sales) FROM Superstore_Sales), 2) AS [Sales Percentage (%)],
	COUNT(Sales) AS [Sales Count],
	ROUND(CAST(COUNT(Sales) AS FLOAT) * 100 / CAST((SELECT COUNT(Sales) FROM Superstore_Sales) AS FLOAT), 2) 
		AS [Sales Count Percentage (%)]
FROM Superstore_Sales
GROUP BY Segment
ORDER BY Segment;
-- 2. Who are the top 20 customers?
SELECT TOP 20
	[Customer ID],
	[Customer Name],
	[Segment],
	SUM(Sales) AS [Sales ($)]
FROM Superstore_Sales
GROUP BY [Customer ID], [Customer Name], [Segment]
ORDER BY [Sales ($)] DESC;
-- 3. Who are the most loyal customers that frequently make repeat orders?
SELECT TOP 20
	[Customer ID],
	[Customer Name],
	[Segment],
	COUNT(Sales) AS [Order Count],
	SUM(Sales) AS [Sales ($)]
FROM Superstore_Sales
GROUP BY [Customer ID], [Customer Name], [Segment]
ORDER BY [Order Count] DESC;
-- 4. How is the sales of the top 50 customers compared to the rest of the other customers?
SELECT
	SUM([Sales ($)]) AS [Sales of Top 50 Customers]
	FROM (SELECT TOP 50 
			  [Customer Name], 
			  SUM(Sales) AS [Sales ($)] 
		  FROM Superstore_Sales 
		  GROUP BY [Customer Name] 
		  ORDER BY [Sales ($)]  DESC) AS Ref1;
SELECT 
	SUM([Sales ($)]) AS [Sales of Non-Top 50 Customers]
	FROM (SELECT 
			  [Customer Name], 
			  SUM(Sales) AS [Sales ($)]  
		  FROM Superstore_Sales 
		  GROUP BY [Customer Name] 
		  ORDER BY [Sales ($)]  DESC
		  OFFSET 50 ROWS
		  FETCH NEXT ((SELECT COUNT(Sales) FROM Superstore_Sales) - 50) ROWS ONLY) AS Ref2;
--
-- C. Product performance:
-- 1. How many products are there?
SELECT COUNT([Product Name]) AS [Product Count]
FROM (SELECT DISTINCT [Product Name] FROM Superstore_Sales) AS ref3;
-- 2. What are the top 10 best performing items in term of sales?
SELECT TOP 10
	[Product ID],
	[Product Name],
	Category,
	[Sub-Category],
	SUM(Sales) AS [Sales ($)]
FROM Superstore_Sales
GROUP BY [Product ID], [Product Name], [Category], [Sub-Category]
ORDER BY [Sales ($)] DESC;
-- 3. What are the top 10 best performing category in term of sales?
SELECT TOP 10
	Category,
	SUM(Sales) AS [Sales ($)]
FROM Superstore_Sales
GROUP BY Category
ORDER BY [Sales ($)] DESC;
-- 4. What are the top 10 best performing sub-category in term of sales?
SELECT TOP 10
	[Sub-Category],
	Category,
	SUM(Sales) AS [Sales ($)]
FROM Superstore_Sales
GROUP BY [Sub-Category], Category
ORDER BY [Sales ($)] DESC;
-- 5. What are 3 worst performing products from each sub-category in term of sales?
SELECT
	[Product ID],
	[Product Name],
	[Sub-Category],
	[Category],
	SUM(Sales) AS [Sales ($)]
INTO WorstProducts
FROM Superstore_Sales
GROUP BY [Product ID], [Product Name], [Sub-Category], [Category]
ORDER BY [Sales ($)];
WITH cte AS
	(SELECT *,
		ROW_NUMBER() OVER (PARTITION BY [Sub-Category] ORDER BY [Sales ($)]) AS rn
	FROM WorstProducts)
SELECT
	[Product ID],
	[Product Name],
	[Sub-Category],
	[Category],
	[Sales ($)]
from cte
WHERE rn BETWEEN 1 AND 3;
--
-- D. Area Performance
-- 1. What are the countries that the store has reached?
SELECT DISTINCT Country FROM Superstore_Sales
-- 2. How is the performace of each region of the US?
SELECT
	Region,
	SUM(Sales) AS [Sales ($)]
FROM Superstore_Sales
GROUP BY Region
ORDER BY [Sales ($)] DESC;
-- 3. What are the top 10 best performing states in term of sales?
SELECT TOP 10
	[State],
	SUM(Sales) AS [Sales ($)]
FROM Superstore_Sales
GROUP BY [State]
ORDER BY [Sales ($)] DESC;
-- 4. Where do orders are made the most?
SELECT TOP 10
	[City],
	[State],
	[Region],
	COUNT([Sales]) AS [Orders Count]
FROM Superstore_Sales
WHERE [Segment] = 'Consumer'
GROUP BY [City], [State], [Region]
ORDER BY [Orders Count] DESC;
-- 5. What are the top cities of each state in term of sales?
SELECT
	[State],
	City,
	SUM(Sales) AS [Sales ($)]
INTO StateCitySales
FROM Superstore_Sales
GROUP BY [State], City
ORDER BY [State], [Sales ($)];
WITH cte AS
	(SELECT *,
	       ROW_NUMBER() OVER (PARTITION BY [State] ORDER BY [Sales ($)] DESC) AS rn
	 FROM StateCitySales)
SELECT 
	[State], 
	City, 
	[Sales ($)]
FROM cte
WHERE rn = 1;
--
------------------------------------------- MULTIVARIATE ANALYSIS -------------------------------------------
--
-- A. Product vs. Customer
-- 1. What are three most popular products for each customer segment?
SELECT
	Segment,
	[Product ID],
	[Product Name],
	[Sub-Category],
	[Category],
	SUM(Sales) AS [Sales ($)]
INTO SegmentPopProduct
FROM Superstore_Sales
GROUP BY Segment, [Product ID], [Product Name], [Sub-Category], [Category]
ORDER BY Segment, [Sales ($)];
WITH cte AS
	(SELECT *,
	       ROW_NUMBER() OVER (PARTITION BY Segment ORDER BY [Sales ($)] DESC) AS rn
	 FROM SegmentPopProduct)
SELECT 
	Segment,
	[Product ID],
	[Product Name],
	[Sub-Category],
	[Category], 
	[Sales ($)]
FROM cte
WHERE rn BETWEEN 1 AND 3;
-- 2. What are the most popular product sub-category for each customer segment?
SELECT
	Segment,
	[Sub-Category],
	[Category],
	SUM(Sales) AS [Sales ($)]
INTO SegmentPopSub
FROM Superstore_Sales
GROUP BY Segment, [Sub-Category], [Category]
ORDER BY Segment, [Sales ($)];
WITH cte2 AS
	(SELECT *,
	       ROW_NUMBER() OVER (PARTITION BY Segment ORDER BY [Sales ($)] DESC) AS rn
	 FROM SegmentPopSub)
SELECT 
	Segment,
	[Sub-Category],
	[Category], 
	[Sales ($)]
FROM cte2
WHERE rn = 1;
--
-- B. Product vs. Shipment
-- 1. What is the average order processing time for each product Category?
SELECT
	[Sub-Category],
	[Category],
	ROUND(AVG(CAST([Ship Date] AS FLOAT) - CAST([Order Date] AS FLOAT)), 2) AS [Average Shipping Time (Days)]
FROM Superstore_Sales
GROUP BY [Sub-Category], [Category]
ORDER BY [Average Shipping Time (Days)];
-- 2. Being the top in ship mode, what are top 3 product sub-categories that use Standard-Class Shipment?
SELECT TOP 3
	[Sub-Category],
	[Category],
	COUNT([Product ID]) AS [Count of Standard Class Shipment]
FROM Superstore_Sales
WHERE [Ship Mode] = 'Standard Class'
GROUP BY [Sub-Category], [Category]
ORDER BY [Count of Standard Class Shipment] DESC;
-- 
-- C. Customer vs. Shipment
-- 1. How is each ship mode category distributed for each customer segment?
SELECT
	[Segment],
	[Ship Mode],
	COUNT([Ship Mode]) AS [Count]
FROM Superstore_Sales
GROUP BY [Segment], [Ship Mode]
ORDER BY [Segment], [Count] DESC;
-- 2. 'Consumer' is the largest portion of customer segment. What ship mode do 'Consumer's use most frequent?
SELECT
	[Ship Mode],
	COUNT([Ship Mode]) AS [Count]
FROM Superstore_Sales
WHERE Segment = 'Consumer' 
GROUP BY [Ship Mode]
ORDER BY [Count] DESC;
--
-- D. Area vs. Product
-- 1. What are three best-performing products in each of the top 5 best performing states?
SELECT TOP 5
		[State],
		SUM(Sales) AS [Sales ($)]
	INTO Top5States
	FROM Superstore_Sales
	GROUP BY [State]
	ORDER BY [Sales ($)] DESC;
SELECT
		[State],
		[Product ID],
		[Product Name],
		[Sub-Category],
		[Category],
		SUM(Sales) AS [Sales ($)]
	INTO StatesProductSales
	FROM Superstore_Sales
	GROUP BY [State], [Product ID], [Product Name], [Sub-Category], [Category]
	ORDER BY [Sales ($)];
SELECT
		t.[State],
		s.[Product ID],
		s.[Product Name],
		s.[Sub-Category],
		s.[Category],
		s.[Sales ($)]
	INTO Top5StatesSalesJoint
	FROM Top5States t
	INNER JOIN StatesProductSales s
	ON t.[State] = s.[State]
	ORDER BY t.[State], s.[Sales ($)] DESC;
WITH cte AS
	(SELECT *,
		ROW_NUMBER() OVER (PARTITION BY [State] ORDER BY [Sales ($)] DESC) AS rn
	FROM Top5StatesSalesJoint)
SELECT
		[State],
		[Product ID],
		[Product Name],
		[Sub-Category],
		[Category],
		[Sales ($)]
	FROM cte
	WHERE rn BETWEEN 1 AND 3;
-- 2. What are the best performing products in each state?
WITH cte AS
	(SELECT *,
		ROW_NUMBER() OVER (PARTITION BY [State] ORDER BY [Sales ($)] DESC) AS rn
	FROM StatesProductSales)
SELECT
	[State],
	[Product ID],
	[Product Name],
	[Sub-Category],
	[Category],
	[Sales ($)]
FROM cte
WHERE rn = 1;
--
------------------------------------------------- END NOTES -------------------------------------------------
--
-- With the data generated by the queries written above, hopefully we can gather some important insights that 
-- might help the decision makers formulating executive decisions to improve the store sales. Combined with
-- other databases containing data related to ads performance and expenses, we can even gather more powerful
-- insights, which unfortunately is not readily available right now. 
--
-- The data visualization of this Superstore Sales dataset is done using Tableau Public, with the link:
-- https://public.tableau.com/views/SuperstoreSalesCustomer/Product?:language=en-US&publish=yes&:display_count=n&:origin=viz_share_link

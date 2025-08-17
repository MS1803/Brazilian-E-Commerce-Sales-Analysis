
CREATE DATABASE Brazilian_ECommerce

use Brazilian_ECommerce

/* Questions which we will solve in SQL After importing data*/
--remember we need to save data in nvarchar value...after that we will do alter our numberic value column datatype

/*
1. Sales & Revenue Performance

	1. Daily / Monthly Revenue Trends – How are sales growing over time?

	2. Top 10 Best-Selling Products – Which products generate the most revenue?

	3. Average Order Value (AOV) – How much do customers spend per order on average?

	4. Revenue by Payment Type – Credit card vs. boleto vs. voucher.

	5. Repeat Customers vs. One-time Buyers – How much revenue comes from repeat customers?

2. Customer Insights

	1. Customer Acquisition by State/City – Where are most of the customers coming from?

	2. Customer Retention Rate – How many customers place multiple orders?

	3. Top 10 Cities by Revenue – Which locations bring the most sales?

	4. Average Delivery Time per Region – Are deliveries slower in certain areas?

	5. New vs. Returning Customers per Month.

3. Seller & Product Insights

	1.	Top Performing Sellers – Which sellers bring the highest revenue?

	2. Average Rating per Seller – Are some sellers consistently rated higher?

	3. Product Categories with Highest Ratings – Which categories have happier customers?

	4. Price Range Analysis per Category – Which categories have premium vs. budget products?

	5. Seller Concentration – How many sellers are active per category?

4. Logistics & Delivery

	1. On-time Delivery Rate – Percentage of orders delivered before the promised date.

	2. Average Shipping Time per Seller – Who ships fastest?

	3. Late Deliveries Impact on Reviews – Does late delivery lower ratings?

	4. Top Cities with Longest Delivery Time.

	5. Orders per Day of Week – Any delivery slowdowns during weekends?

5. Payment Behavior

	1. Installment Usage Analysis – How many customers use multiple payment installments?

	2. Average Installments by Category – Do higher-priced categories have more installments?

	3. Payment Delays Impact on Delivery Time (if payment confirmation affects shipping).
*/


/******************************************** Starting *********************************************************************/

---imported all data as table

--all tables name

select * from INFORMATION_SCHEMA.TABLES

select * from dbo.customers
select * from dbo.geolocation
select * from dbo.order_items
select * from dbo.order_payments
select * from dbo.order_reviews
select * from dbo.orders
select * from dbo.products
select * from dbo.sellers
select * from dbo.product_category_name_translation where product_category_name ='perfumaria'


--created erd digram in database digram ssms

-- rename column name of dbo.product_category_name_translation and deleted firstrow ( reason first row as column name)

--delete from dbo.product_category_name_translation where product_category_name = 'product_category_name'

select * from dbo.product_category_name_translation


--checking column in dbo.geolocation table ( reason not able to set it as primary key column)

select count(geolocation_zip_code_prefix), count(distinct geolocation_zip_code_prefix) from  dbo.geolocation

select distinct geolocation_zip_code_prefix,	geolocation_lat,	geolocation_lng,	geolocation_city,	geolocation_state 
from   dbo.geolocation

--we have approx 3 lakh duplicate rows
--deleting duplicate value :- total rows 261831

with cte as(
select geolocation_zip_code_prefix,	geolocation_lat,	geolocation_lng,	geolocation_city,	geolocation_state 
, ROW_NUMBER()over(partition by geolocation_zip_code_prefix,	geolocation_lat,	geolocation_lng,	geolocation_city,	geolocation_state  order by geolocation_zip_code_prefix) row_num
from   dbo.geolocation) 

delete from cte where row_num >1


--checking lat long colume have duplicate or not

select count(geolocation_lat) , count( distinct geolocation_lat),	count(geolocation_lng),	count(distinct geolocation_lng)
from   dbo.geolocation

---we donot need to join this table because we have all customer and sellers city and state name in given table.

/****************************************************************************************************************/

--1. Sales & Revenue Performance

	--1. Daily / Monthly Revenue Trends – How are sales growing over time?
		-- If you have multiple rows in your data, you’d just sum (price + freight_value) for all rows.

		--# DAILY REVENUE

		SELECT CAST(ORDER_PURCHASE_TIMESTAMP AS DATE) ORDERDATE, ROUND(sum (price + freight_value),2) AS REVENUE 
		FROM [DBO].[ORDERS] AS O
		INNER JOIN [dbo].[order_items] AS OI 
		ON O.ORDER_ID = OI.ORDER_ID
		GROUP BY CAST(ORDER_PURCHASE_TIMESTAMP AS DATE)
		ORDER BY CAST(ORDER_PURCHASE_TIMESTAMP AS DATE) ASC

		--# MONTHLY REVENUE

		SELECT YEAR(CAST(ORDER_PURCHASE_TIMESTAMP AS DATE))AS  [YEAR],
		DATENAME(MONTH,CAST(ORDER_PURCHASE_TIMESTAMP AS DATE)) AS [MONTH], ROUND(sum (price + freight_value),2) AS REVENUE 
		FROM [DBO].[ORDERS] AS O
		INNER JOIN [dbo].[order_items] AS OI 
		ON O.ORDER_ID = OI.ORDER_ID
		GROUP BY YEAR(CAST(ORDER_PURCHASE_TIMESTAMP AS DATE)),
		DATENAME(MONTH,(CAST(ORDER_PURCHASE_TIMESTAMP AS DATE))) ,MONTH(CAST(ORDER_PURCHASE_TIMESTAMP AS DATE))
		ORDER BY YEAR,MONTH(CAST(ORDER_PURCHASE_TIMESTAMP AS DATE)) ASC


--	2. Top 10 Best-Selling Products – Which products generate the most revenue?

		SELECT TOP 10 PRODUCT_ID, ROUND(sum (price + freight_value),2) AS REVENUE  FROM ORDER_ITEMS
		GROUP BY PRODUCT_ID
		ORDER BY REVENUE DESC



-- 3. Average Order Value (AOV) – How much do customers spend per order on average?
		
		SELECT ROUND(AVG(REVENUE),2) AOV FROM (
		SELECT order_id, ROUND(SUM (price + freight_value),2) AS REVENUE FROM order_items
		GROUP BY order_id) t
		

-- 4. Revenue by Payment Type – Credit card vs. boleto vs. voucher.

		SELECT  OP.payment_type,ROUND(SUM (OI.price + OI.freight_value),2) AS REVENUE FROM order_items AS OI
		INNER JOIN  order_payments AS OP ON OI.order_id = OP.order_id
		GROUP BY OP.payment_type

-- 5. Repeat Customers vs. One-time Buyers – How much revenue comes from repeat customers?
		
		SELECT T.CUSTOMER_TYPE, SUM(T.REVENUE) FROM (
		SELECT CASE WHEN COUNT( DISTINCT O.order_id) = 1 THEN 'One-time Buyers' ELSE 'Repeat Customers' END AS CUSTOMER_TYPE,
		ROUND(SUM (OI.price + OI.freight_value),2) AS REVENUE
		FROM orders AS O
		INNER JOIN order_items AS OI ON O.order_id = OI.order_id
		GROUP BY customer_id )T
		GROUP BY T.CUSTOMER_TYPE
		
--2. Customer Insights

	--1. Customer Acquisition by State/City – Where are most of the customers coming from?
		
		SELECT CUSTOMER_CITY, CUSTOMER_STATE, COUNT(*) NUMBER_OF_CUSTOMER FROM customers
		GROUP BY CUSTOMER_CITY, CUSTOMER_STATE
		ORDER BY NUMBER_OF_CUSTOMER DESC


	--2. Customer Retention Rate – How many customers place multiple orders?
			
		WITH REPETED_CUSTOMER AS(
			SELECT customer_id,COUNT(*) AS CNT FROM orders GROUP BY customer_id HAVING COUNT(*) > 1)
			SELECT CAST((SELECT COUNT(*) FROM REPETED_CUSTOMER)* 1.0 / (SELECT COUNT(*) FROM customers)AS DECIMAL(10,2)) AS RTENTION_RATE


	--3. Top 10 Cities by Revenue – Which locations bring the most sales?

		SELECT TOP 10 C.customer_city, ROUND(SUM (OI.price + OI.freight_value),2) AS REVENUE FROM orders AS O
		INNER JOIN order_items AS OI ON O.order_id = OI.order_id 
		INNER JOIN customers AS C ON O.customer_id = C.customer_id
		GROUP BY C.customer_city 
		ORDER BY REVENUE DESC


	--4. Average Delivery Time per Region – Are deliveries slower in certain areas?
		
		--AVG(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS avg_delivery_days

		SELECT  C.customer_state, 
		AVG(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS avg_delivery_days FROM orders AS O
		INNER JOIN order_items AS OI ON O.order_id = OI.order_id 
		INNER JOIN customers AS C ON O.customer_id = C.customer_id
		GROUP BY C.customer_state 
		ORDER BY avg_delivery_days DESC

		--TOP 5 STATE BY AVG DELIVERYDAYS

		SELECT TOP 5 C.customer_state, 
		AVG(DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS avg_delivery_days FROM orders AS O
		INNER JOIN order_items AS OI ON O.order_id = OI.order_id 
		INNER JOIN customers AS C ON O.customer_id = C.customer_id
		GROUP BY C.customer_state 
		ORDER BY avg_delivery_days DESC

--3. Seller & Product Insights

	--1.	Top  Performing Sellers – Which sellers bring the highest revenue?

	SELECT *, DENSE_RANK()OVER(ORDER BY REVENUE) AS RANKING FROM (
	SELECT seller_id, ROUND(SUM (OI.price + OI.freight_value),2) AS REVENUE  FROM order_items AS OI
	GROUP BY seller_id)t
	
	--Top 10 Performing Sellers – Which sellers bring the highest revenue?

	SELECT TOP 10 seller_id, ROUND(SUM (OI.price + OI.freight_value),2) AS REVENUE  FROM order_items AS OI
	GROUP BY seller_id
	ORDER BY REVENUE DESC


	--2. Average Rating per Seller – Are some sellers consistently rated higher?

	SELECT seller_id, AVG(RO.REVIEW_SCORE) AS Average_Rating FROM order_reviews AS RO
	INNER JOIN order_items AS OI ON RO.order_id = OI.order_id
	GROUP BY seller_id
	ORDER BY Average_Rating DESC



	--3. Product Categories with Highest Ratings – Which categories have happier customers?

	SELECT PT.product_category_name_english, AVG(RO.REVIEW_SCORE) AS Average_Rating FROM order_reviews AS RO
	INNER JOIN order_items AS OI ON RO.order_id = OI.order_id
	INNER JOIN products AS P ON OI.product_id = P.product_id
	INNER JOIN [dbo].[product_category_name_translation] PT ON P.product_category_name = PT.product_category_name
	GROUP BY PT.product_category_name_english
	ORDER BY Average_Rating DESC

	--4. Price Range Analysis per Category – Which categories have premium vs. budget products?

	WITH CATEGORY AS(
	SELECT P.product_category_name, AVG(PRICE+freight_value) AVG_PRICE FROM order_items AS OI
	INNER JOIN products AS P ON P.product_id = OI.product_id
	GROUP BY P.product_category_name)
	SELECT product_category_name, 
	CASE WHEN AVG_PRICE>500 THEN 'PREMIUM PRODUCTS' ELSE 'budget products' END AS PRICE_CATEGORY FROM CATEGORY

	--5. Seller Concentration – How many sellers are active per category?

	SELECT P.product_category_name, COUNT(DISTINCT seller_id) AS NUMBER_OF_SELLER FROM order_items AS OI
	INNER JOIN products AS P ON P.product_id = OI.product_id
	GROUP BY P.product_category_name
	ORDER BY NUMBER_OF_SELLER DESC

	--IF YOU DON'T NEED NULL VALUE
	SELECT P.product_category_name, COUNT(DISTINCT seller_id) AS NUMBER_OF_SELLER FROM order_items AS OI
	INNER JOIN products AS P ON P.product_id = OI.product_id
	WHERE P.product_category_name IS NOT NULL
	GROUP BY P.product_category_name
	ORDER BY NUMBER_OF_SELLER DESC


--4. Logistics & Delivery

	--1. On-time Delivery Rate – Percentage of orders delivered before the promised date.

		SELECT 
			ROUND(CAST(SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) AS FLOAT) 
			/ COUNT(*) * 100,2)  AS on_time_delivery_rate
		FROM orders;

	--2. Average Shipping Time per Seller – Who ships fastest?


		SELECT 
		OT.SELLER_ID,
		AVG(DATEDIFF(day, order_purchase_timestamp,order_delivered_customer_date)) AS avg_shipping_days
		FROM orders O
		INNER JOIN ORDER_ITEMS OT ON O.order_id = OT.order_id
		GROUP BY OT.SELLER_ID
		ORDER BY avg_shipping_days ASC;  -- Fastest first

	--3. Late Deliveries Impact on Reviews – Does late delivery lower ratings?


	SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On-Time'
        ELSE 'Late'
        END AS delivery_status,
        COUNT(*) AS total_orders,
        AVG(review_score * 1.0) AS avg_rating
     FROM orders a
     INNER JOIN order_reviews B ON A.order_id = B.order_id 
     WHERE review_score IS NOT NULL
        GROUP BY CASE 
             WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On-Time'
             ELSE 'Late'
     END;
		
		--ROUNDED PAYMENT VALUES FROM MULTIPLE DECIMAL PLACES TO 2 PLACES

		UPDATE order_payments SET payment_value = ROUND(payment_value,2) 
		FROM order_payments WHERE payment_value = payment_value
		


	--4. Top Cities with Longest Delivery Time.

	SELECT top 10
    customer_city,
    AVG(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) AS avg_delivery_days
		FROM orders a
		inner join customers b on a.customer_id = b.customer_id
		GROUP BY customer_city
		ORDER BY avg_delivery_days DESC


	--5. Orders per Day of Week – Any delivery slowdowns during weekends?


	SELECT 
       DATENAME(WEEKDAY, order_purchase_timestamp) AS day_of_week,
       COUNT(*) AS total_orders,
       AVG(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) AS avg_delivery_days
   FROM orders
       GROUP BY DATENAME(WEEKDAY, order_purchase_timestamp)
       ORDER BY total_orders DESC;

5. Payment Behavior

	--1. Installment Usage Analysis – How many customers use multiple payment installments?


	SELECT COUNT(*) AS CUSTOMERS_WITH_MULTIPLE_INSTALLMENTS FROM  order_payments a
		INNER JOIN orders B ON A.order_id = B.order_id
		WHERE A.payment_installments <> 1
		

	--2. Average Installments by Category – Do higher-priced categories have more installments?


	SELECT
	D.product_category_name_english AS CATEGORY, 
	AVG(payment_installments ) AS AVG_INSTALLMENTS,
    ROUND(AVG(payment_value ),2) AS AVG_PRICE
	FROM order_payments A
		INNER JOIN order_items B ON A.order_id = B.order_id
		INNER JOIN products C ON C.product_id = B.product_id
		INNER JOIN product_category_name_translation D ON C.product_category_name = D.product_category_name_english
		GROUP BY D.product_category_name_english


	--3. Payment Delays Impact on Delivery Time (if payment confirmation affects shipping).


	SELECT 
    CASE 
        WHEN DATEDIFF(day, order_purchase_timestamp, order_approved_at) > 0 THEN 'DELAYED PAYMENTS'
        ELSE 'SAME-DAY PAYMENTS'
    END AS PAYMENT_STATUS,
    COUNT(*) AS TOTAL_ORDERS,
    AVG(DATEDIFF(day, order_purchase_timestamp, order_approved_at)) AS AVG_PAYMENT_DAYS,
    AVG(DATEDIFF(day, order_purchase_timestamp, order_approved_at)) AS AVG_DELIVERY_DAYS
FROM orders
GROUP BY CASE 
             WHEN DATEDIFF(day, order_purchase_timestamp, order_approved_at) > 0 THEN 'DELAYED PAYMENTS'
             ELSE 'SAME-DAY PAYMENTS'
         END;
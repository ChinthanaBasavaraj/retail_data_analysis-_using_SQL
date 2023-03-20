
CREATE DATABASE db_SQL_CS

--DATA CLEANING
--Q1
--What is the total number of rows in each of the 3 tables in the database?
SELECT 'CUSTOMER' AS TABLE_NAME, COUNT(*) AS NO_OF_RECORDS 
		FROM CUSTOMER 
			UNION ALL
			SELECT 'PROD_CAT_INFO' AS TABLE_NAME, COUNT(*) AS NO_OF_RECORDS
			FROM  PROD_CAT_INFO
			UNION ALL
			SELECT 'TRANSACTIONS' AS TABLE_NAME, COUNT(*) AS NO_OF_RECORDS
			FROM TRANSACTIONS
			


--Q2
--What is the toatl number of transactions that have a return?
SELECT COUNT(TRANSACTION_ID) AS 'NO_OF_RETURNS'
FROM TRANSACTIONS
WHERE QTY<0

--Q3
--Convert the date variables into date format
UPDATE CUSTOMER
SET DOB = CONVERT(DATE,DOB,103)

ALTER TABLE CUSTOMER
ALTER COLUMN DOB DATE

UPDATE TRANSACTIONS
SET TRAN_DATE=CONVERT(DATE,TRAN_DATE,103)

ALTER TABLE TRANSACTIONS
ALTER COLUMN TRAN_DATE DATE

--Q4
--What is the time range of the transaction data available for analysis?
SELECT min(tran_date) AS START_TRAN_DATE, MAX(TRAN_DATE) AS END_TRAN_DATE,
		DATEDIFF(DAY, MIN(TRAN_DATE), MAX(TRAN_DATE)) AS NUMBER_OF_DAYS,
		DATEDIFF(MONTH, MIN(TRAN_DATE), MAX(TRAN_DATE)) AS NUMBER_OF_MONTHS,
		DATEDIFF(YEAR, MIN(TRAN_DATE), MAX(TRAN_DATE)) AS NUMBER_OF_YEARS
FROM TRANSACTIONS


--Q5
--Which product category does subcategory"DIY" belong to?
SELECT PROD_SUBCAT, PROD_CAT
FROM PROD_CAT_INFO
WHERE PROD_SUBCAT='DIY'


--DATA ANALYSIS
--Q1
--Which channel is most used for transactions?
SELECT TOP 1 STORE_TYPE ,COUNT(STORE_TYPE) AS COUNT
FROM TRANSACTIONS
GROUP BY STORE_TYPE
ORDER BY COUNT DESC


--Q2
--What is the count of male and female customers in the database?
SELECT GENDER, COUNT(*)
FROM CUSTOMER
WHERE GENDER!=' '
GROUP BY GENDER


--Q3
--From ehich city do we have trhe maximum customers and how many?
SELECT TOP 1 CITY_CODE, COUNT(CUST_ID) AS NUMBER_OF_CUSTOMERS
FROM TRANSACTIONS AS T1 LEFT JOIN CUSTOMER AS T2
ON T1.CUST_ID=T2.CUSTOMER_ID
GROUP BY CITY_CODE
ORDER BY NUMBER_OF_CUSTOMERS DESC


--Q4
--How many subcategories are there under books category?
SELECT COUNT(PROD_SUBCAT) AS 'NO_OF_SUBCAT'
FROM PROD_CAT_INFO
WHERE PROD_CAT='BOOKS'

--Q5
--What is the maximum quantity ever ordered?
SELECT MAX(QTY) AS 'MAX_QTY'
FROM TRANSACTIONS
WHERE QTY>0

--Q6
--Net total revenue generated in electronics and books category
SELECT SUM(TOTAL_AMT) AS TOTAL_NET_REVENUE
FROM TRANSACTIONS AS T2 
WHERE T2.PROD_CAT_CODE = (SELECT DISTINCT PROD_CAT_CODE 
						FROM PROD_CAT_INFO
						WHERE PROD_CAT ='ELECTRONICS') 
UNION ALL
SELECT SUM(TOTAL_AMT) AS TOTAL_NET_REVENUE
FROM TRANSACTIONS AS T2
WHERE T2.PROD_CAT_CODE = (SELECT DISTINCT PROD_CAT_CODE
					FROM PROD_CAT_INFO
					WHERE PROD_CAT ='BOOKS') 


--Q7
--How many cutsomers have more than 10 transactions excluding returns?
SELECT COUNT(CUST_ID) AS NUMBER_OF_CUSTOMERS
FROM (SELECT CUST_ID, COUNT(*) AS 'NO_OF_TRANS'
	FROM TRANSACTIONS
	WHERE QTY>0
	GROUP BY CUST_ID
	HAVING COUNT(*)>10) AS t1

--Q8
--Combined revenue earned from electronics and books category from flagshiop stores
SELECT SUM(TOTAL_AMT) AS COMBINED_REVENUE
FROM TRANSACTIONS
WHERE PROD_CAT_CODE IN (SELECT PROD_CAT_CODE
						FROM PROD_CAT_INFO
						WHERE PROD_CAT IN ('ELECTRONICS', 'CLOTHING')) AND STORE_TYPE='FLAGSHIP STORE'

--Q9
--Total revenue genaerated from mmale customers in electronics category? Output should display total revenue by subcategory
SELECT T3.PROD_SUBCAT, SUM(TOTAL_AMT) AS TOTAL_REVENUE
FROM CUSTOMER AS T1 LEFT JOIN TRANSACTIONS AS T2
ON T1.CUSTOMER_ID=T2.CUST_ID
LEFT JOIN PROD_CAT_INFO AS T3
ON T2.PROD_CAT_CODE=T3.PROD_CAT_CODE AND T2.PROD_SUBCAT_CODE=T3.PROD_SUB_CAT_CODE
WHERE T2.PROD_CAT_CODE=(SELECT DISTINCT PROD_CAT_CODE
						FROM PROD_CAT_INFO
						WHERE PROD_CAT='ELECTRONICS') AND GENDER='M'
GROUP BY T3.PROD_SUBCAT


--Q10
--Percentage of sales and returns by product subcactegory .Display only top 5 categories in terms of sales

ALTER TABLE TRANSACTIONS
ALTER COLUMN QTY NUMERIC(5,2)

SELECT top 5 prod_cat, sum(total_amt), FORMAT(CONVERT(DECIMAL(8,2), SALES)/(CONVERT(DECIMAL(8,2), SALES+RETURNS), 'p') else null end as percentage
FROM (
select
[Subcategory] = P.prod_subcat,
[Sales] =   Round(SUM(cast( case when T.Qty > 0 then total_amt else 0 end as float)),2) , 
[Returns] = Round(SUM(cast( case when T.Qty < 0 then total_amt else 0 end as float)),2) 
from Transactions as T
INNER JOIN prod_cat_info as P ON T.prod_subcat_code = P.prod_sub_cat_code
group by P.prod_subcat)


--Q11
--For ll customers aged between 25 and 35 years what is the net total revenue generated in the last 30 days of transactions from max transaction available in the data?

SELECT CUSTOMER_ID, (DATEPART(YEAR,GETDATE())- DATEPART(YEAR, DOB)) AS AGE,  SUM(TOTAL_AMT) AS NET_TOTAL_REVENUE
FROM CUSTOMER AS T1 LEFT JOIN TRANSACTIONS AS T2
ON T1.CUSTOMER_ID=T2.CUST_ID
WHERE (DATEPART(YEAR,GETDATE())- DATEPART(YEAR, DOB))>25 AND (DATEPART(YEAR,GETDATE())- DATEPART(YEAR, DOB))<35 AND TRAN_DATE>= DATEADD(DAY,-30,(SELECT MAX(TRAN_DATE) FROM TRANSACTIONS))
GROUP BY CUSTOMER_ID, (DATEPART(YEAR,GETDATE())- DATEPART(YEAR, DOB))


--Q12
--Which product category has seen the max value of returns in the last 3 months of transactions?

SELECT TOP 1 PROD_CAT, SUM(ABS(TOTAL_AMT)) AS 'VALUE_OF_RETURNS'
FROM PROD_CAT_INFO AS T1 LEFT JOIN TRANSACTIONS AS T2
ON T1.PROD_CAT_CODE=T2.PROD_CAT_CODE
WHERE QTY<0 AND TRAN_DATE>= DATEADD(MONTH, -3, (SELECT MAX(TRAN_DATE) FROM TRANSACTIONS))
GROUP BY PROD_CAT
ORDER BY 'VALUE_OF_RETURNS' DESC

--Q13
--Which store type sells the maximum products by value of sales amount and by quantity sold?

select TOP 1 STORE_TYPE,SUM(QTY) AS QUANTITY, SUM(TOTAL_AMT) AS SALES
from TRANSACTIONS
WHERE QTY>0
GROUP BY STORE_TYPE
ORDER BY QUANTITY DESC, SALES DESC

--Q14
--What are the categories for which the average revenue above overall average?
SELECT PROD_CAT, AVG(TOTAL_AMT) AS AVG_REVENUE
FROM PROD_CAT_INFO AS T1 LEFT JOIN TRANSACTIONS AS T2
ON T1.PROD_CAT_CODE=T2.PROD_CAT_CODE
GROUP BY PROD_CAT
HAVING AVG(TOTAL_AMT) > (SELECT AVG(TOTAL_AMT)
						FROM TRANSACTIONS)


--Q15
--Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold

SELECT PROD_SUBCAT, PROD_CAT, AVG(TOTAL_AMT) AS AVG_REVENUE, SUM(TOTAL_AMT) AS TOTAL_REVENUE
FROM PROD_CAT_INFO AS T1 LEFT JOIN TRANSACTIONS AS T2
ON T1.PROD_CAT_CODE=T2.PROD_CAT_CODE
WHERE T2.PROD_CAT_CODE IN ( SELECT TOP 5 PROD_CAT_CODE
						FROM TRANSACTIONS
						GROUP BY PROD_CAT_CODE 
						ORDER BY SUM(QTY) DESC)
GROUP BY PROD_SUBCAT, PROD_CAT

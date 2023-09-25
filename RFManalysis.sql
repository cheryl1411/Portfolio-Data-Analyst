SELECT * FROM [dbo].[rfm]

ALTER TABLE [dbo].[rfm]
ADD days_since_order INT

UPDATE [dbo].[rfm]
SET days_since_order = DATEDIFF(Day, [Order_Date], '2023-01-01')

-- Create new table to create segment customer
CREATE TABLE customer_segmentation 
(
    Customer_ID NVARCHAR(255),
    last_active_date DATE,
    recency INT,
    frequency INT,
    monetary DECIMAL(18, 2), -- Adjust the data type as needed
    frequency_percent_rank DECIMAL(18, 2), -- Adjust the data type as needed
    monetary_percent_rank DECIMAL(18, 2), -- Adjust the data type as needed
    recency_rank INT,
    frequency_rank INT,
    monetary_rank INT,
    rfm_ranking VARCHAR(10), -- Adjust the data type as needed
    rfm_segment VARCHAR(50))


-- Classify customer groups according to RFM model
WITH rfm_metrics AS (
    SELECT
        DISTINCT[Customer_ID],
		MAX([Order_Date]) AS last_active_date,
        DATEDIFF(DAY, MAX([Order_Date]), '2023-01-01')AS recency,
        COUNT(DISTINCT [Order_ID]) AS frequency,
        SUM([Sales] * [Quantity]) AS monetary
    FROM [dbo].[rfm]
    WHERE [Order_Date] >= DATEADD(YEAR, -1, '2023-01-01')
    GROUP BY [Customer_ID]),
-- Using Window function: 
    rfm_percent_rank AS (
    SELECT 
        *, 
        PERCENT_RANK() OVER (ORDER BY [frequency]) AS frequency_percent_rank,
        PERCENT_RANK() OVER (ORDER BY [monetary]) AS monetary_percent_rank
    FROM rfm_metrics),

    rfm_rank AS (
    SELECT *,
        CASE 
            WHEN recency BETWEEN 0 AND 100 THEN 3
            WHEN recency BETWEEN 100 AND 200 THEN 2
            WHEN recency BETWEEN 200 AND 370 THEN 1
            ELSE 0
            END
            AS recency_rank,
        CASE 
            WHEN frequency_percent_rank BETWEEN  0.8 AND 1 THEN 3
            WHEN frequency_percent_rank BETWEEN 0.5 AND 0.8 THEN 2
            WHEN frequency_percent_rank BETWEEN 0 AND 0.5 THEN 1
            ELSE 0
            END 
            AS frequency_rank,
         CASE 
            WHEN monetary_percent_rank BETWEEN  0.8 AND 1 THEN 3
            WHEN monetary_percent_rank  BETWEEN 0.5 AND 0.8 THEN 2
            WHEN monetary_percent_rank  BETWEEN 0 AND 0.5 THEN 1
            ELSE 0
            END
            AS monetary_rank
    FROM  rfm_percent_rank),

    rfm_rank_concat AS (
    SELECT *,
        CONCAT (recency_rank, frequency_rank, monetary_rank) AS rfm_ranking
    FROM rfm_rank),

    rfm_segment AS (
    SELECT *,
        CASE
            WHEN rfm_ranking IN ('333', '323','332') THEN 'Loyal'
            WHEN rfm_ranking IN ('321', '222', '232', '331', '322','233', '223') THEN 'Active'
            WHEN rfm_ranking IN ('111','121','122','123','132', '211', '131','112','113', '133') THEN 'Churners'
            WHEN rfm_ranking IN ('313', '312', '311') THEN 'New Customers'
            WHEN rfm_ranking IN ('221', '231', '311', '212', '213') THEN 'Potential churners'
            ELSE '0'
            END
            AS rfm_segment
    FROM rfm_rank_concat)
    INSERT INTO [dbo].[customer_segmentation] (Customer_ID, last_active_date, recency, frequency, monetary, frequency_percent_rank, monetary_percent_rank, recency_rank, frequency_rank, monetary_rank, rfm_ranking, rfm_segment)
    SELECT  [Customer_ID],
            last_active_date,
            recency,
            frequency,
            monetary,
            frequency_percent_rank,
            monetary_percent_rank,
            recency_rank,
            frequency_rank,
            monetary_rank,
            rfm_ranking,
            rfm_segment
    FROM rfm_segment

    SELECT *
    FROM [dbo].[customer_segmentation]

-- Finding revenue distribution of each segmentation: 
SELECT (SELECT SUM([monetary]) AS total_revenue
FROM [dbo].[customer_segmentation]
WHERE rfm_segment = 'New Customers')/ (SELECT SUM([monetary]) FROM [dbo].[customer_segmentation]) *100 AS percentage_sales -- Change WHERE to get each segmentation value. 

-- avg Frequency time
    SELECT AVG(frequency)
    FROM [dbo].[customer_segmentation]
    WHERE rfm_segment = 'New Customers' -- change group customer to find their avg purchase time. 
-- AVG spending:
SELECT AVG([monetary]/[recency])AS avg_spending
FROM [dbo].[customer_segmentation]
WHERE rfm_segment = 'Potential Churners'-- change group customer to find their avg spending on order. 

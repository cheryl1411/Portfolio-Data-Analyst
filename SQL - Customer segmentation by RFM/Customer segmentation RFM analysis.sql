SELECT * FROM SALE.sales;

SET SQL_SAFE_UPDATES = 0;
-- Add a new column "adjusted_date" to calculate the days since the order date
ALTER TABLE SALE.sales
ADD COLUMN days_since_order INT;

-- Update the new column with the calculated values: because this is old data, so I I pretend current date 1st March 2018
UPDATE SALE.sales
SET days_since_order = DATEDIFF('2018-03-01', `Order Date`);
-- filter data for closest year only :

WITH rfm_metrics AS (
	SELECT `Customer ID`,
		MAX(`Order Date`) AS last_active_date,
		MAX(days_since_order) AS recency,
		COUNT(DISTINCT `Order ID`) AS frequency,
		SUM(Sales * Quantity) AS monetary 
	FROM SALE.sales
	WHERE
	`Order Date` >= DATE_SUB('2018-03-01', INTERVAL 1 YEAR)
	GROUP BY
	`Customer ID`)
, rfm_rank AS (
SELECT *,
    NTILE(4) OVER (ORDER BY recency DESC) AS rfm_recency,
    NTILE(4) OVER (ORDER BY frequency DESC) AS rfm_frequency,
    NTILE(4) OVER (ORDER BY monetary DESC) AS rfm_monetary
FROM rfm_metrics
ORDER BY recency DESC)
, rfm_rank_concat AS(
SELECT *, 
	CONCAT(rfm_recency, rfm_frequency, rfm_monetary) AS rfm_rank 
FROM rfm_rank)
, rfm_segment AS (
SELECT *,
	CASE 
		WHEN rfm_rank IN ('444','443','434','433','442') THEN 'loyal'
        WHEN rfm_rank IN ('323','332','321','422', '432', '333','324','342', '431', '441') THEN 'active' -- buy frequently but low prices
        WHEN rfm_rank IN ('322','222','233','322', '312','223','224','221','232','213') THEN 'potential churners'
        WHEN rfm_rank IN ('311','411','331','312','341', '431') THEN 'new customers'
        WHEN rfm_rank IN ('133','134','143','244','334', '343', '344', '234', '423','424') THEN 'big spenders, slipping away' 
        WHEN rfm_rank IN ('111','121','122','123','132', '211', '212', '114', '141', '124', '131','112','113','241') THEN 'lost customers'
        END 
        AS rfm_segment
FROM rfm_rank_concat
ORDER BY rfm_rank DESC)
SELECT *
FROM rfm_segment;


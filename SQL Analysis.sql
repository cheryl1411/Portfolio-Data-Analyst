-- Inspecting Data:
SELECT * FROM sales.adidas_us;

-- Checking unique values:
SELECT DISTINCT EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) AS invoice_year FROM sales.adidas_us; -- nice to plot
SELECT DISTINCT state FROM sales.adidas_us;
SELECT DISTINCT product FROM sales.adidas_us; -- nice to plot
SELECT DISTINCT sales_method FROM sales.adidas_us; -- nice to plot
SELECT DISTINCT retailer FROM sales.adidas_us; -- nice to plot

-- QUESTION:
-- 1.	What's the total revenue and profitability of the dataset? (entire dataset, 2020 and 2021)

SELECT
    SUM(CASE WHEN EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2020 THEN total_sales ELSE 0 END) AS revenue_2020,
    SUM(CASE WHEN EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2020 THEN operating_profit ELSE 0 END) AS profit_2020,
    SUM(CASE WHEN EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2021 THEN total_sales ELSE 0 END) AS revenue_2021,
    SUM(CASE WHEN EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2021 THEN operating_profit ELSE 0 END) AS profit_2021,
    SUM(total_sales) AS total_revenue,
    SUM(operating_profit) AS total_profit
FROM
    sales.adidas_us;
    
-- 2. Which states drive the most revenue and have high profitability?
SELECT state, 
	SUM(total_sales) AS revenue, 
	SUM(operating_profit) AS profit
FROM sales.adidas_us
GROUP BY state
ORDER BY revenue DESC;

    -- 3. Are there any states that consistently show higher operating margins? 
SELECT
    y2020.state,
    y2020.avg_margin_2020,
    y2021.avg_margin_2021,
    y2021.avg_margin_2021 - y2020.avg_margin_2020 AS margin_change
FROM
    (SELECT state, 
			AVG(operating_margin) AS avg_margin_2020
    FROM sales.adidas_us
    WHERE EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2020
    GROUP BY state) AS y2020
JOIN
    (SELECT state, 
			AVG(operating_margin) AS avg_margin_2021
    FROM sales.adidas_us
    WHERE EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2021
    GROUP BY state) AS y2021
ON y2020.state = y2021.state
WHERE (y2021.avg_margin_2021 - y2020.avg_margin_2020) > 0;


-- 4. Are certain sales methods consistently more profitable?
-- •	Overall sales by selling method
SELECT sales_method,
	SUM(total_sales) AS revenue,
    SUM(operating_profit) AS profit,
	AVG(operating_margin) AS avg_margin
FROM sales.adidas_us
GROUP by sales_method
ORDER BY profit DESC;

-- Identify any trends or patterns in the profitability of different sales methods?
SELECT
    sales_method,
    EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) AS invoice_year,
    SUM(operating_profit) AS profit, AVG(operating_margin) AS avg_margin
FROM sales.adidas_us
GROUP BY sales_method, invoice_year
ORDER BY sales_method, invoice_year;

-- 5.	Is high sales volume correlated with high profits? 0.892 close to +1 => possitive correlation
SELECT
    (COUNT(*) * SUM(units_sold * operating_profit) - SUM(units_sold) * SUM(operating_profit)) /
    SQRT((COUNT(*) * SUM(units_sold * units_sold) - SUM(units_sold) * SUM(units_sold)) *
         (COUNT(*) * SUM(operating_profit * operating_profit) - SUM(operating_profit) * SUM(operating_profit))) AS correlation_coefficient
FROM sales.adidas_us;
-- 6.	Do revenue and profitability follow seasonal trends? (2021, 2022) -- Use for visual time trend
SELECT
    EXTRACT(MONTH FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) AS month,
    SUM(total_sales) AS revenue,
    AVG(operating_profit) AS avg_profit
FROM sales.adidas_us
WHERE EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2020
GROUP BY month
ORDER BY revenue DESC;

SELECT
    EXTRACT(MONTH FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) AS month,
    SUM(total_sales) AS revenue,
    SUM(operating_profit) AS profit
FROM sales.adidas_us
WHERE EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2021
GROUP BY month
ORDER BY revenue DESC;

-- 7. Product
-- Top selling product and highest profitability entire dataset 
SELECT product,
    SUM(CASE WHEN EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2020 THEN total_sales END) AS revenue_2020,
    SUM(CASE WHEN EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2020 THEN units_sold END) AS total_units_2020,
    SUM(CASE WHEN EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2021 THEN total_sales END) AS revenue_2021,
    SUM(CASE WHEN EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2021 THEN units_sold END) AS total_units_2021,
    SUM(total_sales) as total_revenue,
    SUM(operating_profit) AS total_profit,
    AVG(operating_margin) AS avg_margin
FROM sales.adidas_us
GROUP BY product
ORDER BY 6,7 DESC;

-- AVG Price
SELECT
    product,
    AVG(CASE WHEN EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2020 THEN price_per_unit END) AS avg_price_2020,
    AVG(CASE WHEN EXTRACT(YEAR FROM STR_TO_DATE(invoice_date, '%d/%m/%Y')) = 2021 THEN price_per_unit END) AS avg_price_2021,
    AVG(price_per_unit) AS avg_price
FROM sales.adidas_us
GROUP BY product;








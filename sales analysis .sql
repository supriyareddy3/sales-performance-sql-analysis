

Select *
from products;
Select *
from sales_pipeline;
Select *
from accounts;
Select *
from sales_teams;


--Calculate the number of sales opportunities created each month using "engage_date", 
--and identify the month with the most opportunities

select 
      YEAR(engage_date) AS year,
      month(engage_date) AS month,
      Count(*) as total_opportunities
 FROM sales_pipeline
 WHERE engage_date is not null
 Group by YEAR(engage_date),
          MONTH(engage_date)
Order by total_opportunities DESC



--Find the average time deals stayed open (from "engage_date" to "close_date"), 
--and compare closed deals versus won deals

Select 
      'All closed deals' AS deal_Type,
       AVG(DATEDIFF(day,engage_date,close_date)) as average_deals_opendays
from sales_pipeline
where close_date is not null

union all

Select 
       'Win deals',
       AVG(DATEDIFF(day,engage_date,close_date)) 
from sales_pipeline
where deal_stage ='Won'
and close_date is not null;


--Calculate the percentage of deals in each stage, and determine what share were lost
SELECT
    deal_stage,
  count(*) as count_eachstage,
    count(*)*100/(select count(*) from sales_pipeline) as percentage_of_deals
    
FROM sales_pipeline
GROUP by deal_stage
order by percentage_of_deals DESC
    

--Compute the win rate for each product, and identify which one had the highest win rate


SELECT
    t.product,
    w.won_deals * 100/ t.total_deals AS win_rate
FROM
(
    SELECT product, COUNT(*) AS total_deals
    FROM sales_pipeline
    GROUP BY product
) t
JOIN
(
    SELECT product, COUNT(*) AS won_deals
    FROM sales_pipeline
    WHERE deal_stage = 'Won'
    GROUP BY product
) w
ON t.product = w.product;

--Calculate the win rate for each sales agent, and find the top performer
SELECT 
     sales_agent,
     SUM(CASE WHEN deal_stage = 'Won' 
     THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS win_rate
FROM sales_pipeline
GROUP BY sales_agent
ORDER BY win_rate DESC

--Calculate the total revenue by agent, and see who generated the most
SELECT
     sales_agent,
     SUM(close_value) AS Total_revenue
FROM sales_pipeline
WHERE deal_stage='won'
GROUP BY sales_agent
ORDER BY  Total_revenue

--Calculate win rates by manager to determine which manager’s team performed best
SELECT 
     manager,
     SUM(CASE WHEN deal_stage = 'Won' 
     THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS win_rate
FROM sales_pipeline AS SP
join sales_teams AS ST
ON SP.sales_agent=ST.sales_agent
GROUP BY manager
HAVING COUNT(*) > 10
ORDER BY win_rate DESC

--For the product GTX Plus Pro, find which regional office sold the most units
SELECT TOP 1
     regional_office,
     SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END)  AS items_sold
FROM sales_pipeline AS SP
join sales_teams AS ST
ON SP.sales_agent=ST.sales_agent
WHERE product='GTX PLUS PRO'
GROUP BY regional_office
ORDER BY items_sold DESC

--For March deals, identify the top product by revenue and compare it to the top by units sold
SELECT
        product,
       SUM(close_value) AS revenue,
       count(*) AS units_sold
FROM sales_pipeline
WHERE deal_stage='Won' and MONTH(close_date)=3
GROUP by product
Order by 2 DESC

--Calculate the average difference between "sales_price" and "close_value" 
--for each product, and note if the results suggest a data issue
SELECT SP.product,
      AVG(sales_price-close_value) as AVG_diff
FROM sales_pipeline AS SP
JOIN products AS P
ON SP.product=P.product
WHERE deal_stage='Won'
GROUP BY SP.product

--Calculate total revenue by product series and compare their performance
 SELECT P.series,     
      sum(close_value) AS Total_revenue
FROM sales_pipeline AS SP
JOIN products AS P
ON SP.product=P.product
GROUP BY P.series

--	Calculate revenue by office location, and identify the lowest performer
SELECT  TOP 1
        A.office_location,
        sum(close_value) AS Total_revenue
FROM accounts AS A
JOIN sales_pipeline AS SP
ON A.account=SP.account
WHERE deal_stage='Won'
GROUP BY office_location
ORDER BY 2 ASC
--Find the gap in years between the oldest and newest customer, and name those companies
SELECT  
        MAX(year_established)-Min(year_established) AS gap
FROM accounts
ORDER BY gap DESC

--Which accounts that were subsidiaries had the most lost sales opportunities?
SELECT a.account,
      count(opportunity_id) as opportunities
FROM accounts as a
JOIN sales_pipeline as sp
ON a.account=sp.account
WHERE subsidiary_of is NOT Null 
        AND deal_stage='Lost'
GROUP BY a.account
ORDER BY 2 desc

--Join the companies to their subsidiaries. Which one had the highest total revenue?

SELECT
    CASE
        WHEN a.subsidiary_of IS NULL THEN a.account
        ELSE a.subsidiary_of
    END AS account_group,
    SUM(sp.close_value) AS total_revenue
FROM accounts AS a
JOIN sales_pipeline AS sp
    ON a.account = sp.account
WHERE sp.deal_stage = 'Won'
GROUP BY
    CASE
        WHEN a.subsidiary_of IS NULL THEN a.account
        ELSE a.subsidiary_of
    END
ORDER BY total_revenue DESC;
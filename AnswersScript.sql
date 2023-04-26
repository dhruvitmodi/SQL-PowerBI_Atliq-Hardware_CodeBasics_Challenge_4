
-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region

select distinct market 
from gdb023.dim_customer nolock
where
	customer = 'Atliq Exclusive'
AND region = 'APAC'


-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
--    unique_products_2020, unique_products_2021, percentage_chg


declare @unique_products_2020 AS INT
declare @unique_products_2021 AS INT

;with unique_prod2020_CTE AS (
select product_code, COUNT(product_code) as 'UniqueCount'
from [gdb023].[fact_sales_monthly] nolock 
where fiscal_year = 2020
group by product_code
) 
select @unique_products_2020 = Count(product_code) from unique_prod2020_CTE;

;with unique_prod2021_CTE AS (
select product_code, COUNT(product_code) as 'UniqueCount'
from [gdb023].[fact_sales_monthly] nolock 
where fiscal_year = 2021
group by product_code
) 
select @unique_products_2021 = Count(product_code) from unique_prod2021_CTE;

select 
	@unique_products_2020 AS 'unique_products_2020', 
	@unique_products_2021 AS 'unique_products_2021',
	(((@unique_products_2021 - @unique_products_2020)* 100 ) / @unique_products_2020 ) AS 'percentage_chg'
	
	
	
-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
-- The final output contains 2 fields :segment, product_count


 select segment, COUNT(segment) AS 'product_count' 
 from [gdb023].[dim_product] nolock
 group by segment
 order by 2 desc
 
 
 
 
-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields: segment, product_count_2020, product_count_2021, difference
 
 
-- FOR 2020 
 select segment, PRD.product_code, COUNT(PRD.product_code) AS 'UniqueCount'
 into #T1
 from [gdb023].[dim_product] (NOLOCK) PRD
 INNER JOIN [gdb023].[fact_sales_monthly] (NOLOCK) FSM ON FSM.product_code = PRD.product_code
 where
	FSM.fiscal_year = 2020
 group by segment, PRD.product_code
 
 select segment, COUNT(segment) AS 'UniqueProduct' 
 into #T2
 from #T1
 group by segment
 order by 1 

  
-- FOR 2021
 select segment, PRD.product_code, COUNT(PRD.product_code) AS 'UniqueCount'
 into #T3
 from [gdb023].[dim_product] (NOLOCK) PRD
 INNER JOIN [gdb023].[fact_sales_monthly] (NOLOCK) FSM ON FSM.product_code = PRD.product_code
 where
	FSM.fiscal_year = 2021
 group by segment, PRD.product_code
 
 select segment, COUNT(segment) AS 'UniqueProduct' 
 into #T4
 from #T3
 group by segment
 order by 1 


 -- Final Output
 select #T2.segment, #T2.UniqueProduct AS 'product_count_2020', #T4.UniqueProduct AS 'product_count_2021',
 (#T4.UniqueProduct - #T2.UniqueProduct) AS 'difference'
 from #T2
 INNER JOIN #T4 ON #T2.segment = #T4.segment

 drop table #T1
 drop table #T2
 drop table #T3
 drop table #T4
 
 
 
 
-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields : product_code, product, manufacturing_cost
 
 
select * from 
(
select TOP 1 FMC.product_code, PRD.product, MAX(manufacturing_cost) AS 'manufacturing_cost'
from [gdb023].[fact_manufacturing_cost] (NOLOCK) FMC
INNER JOIN [gdb023].[dim_product] (NOLOCK) PRD ON PRD.product_code = FMC.product_code
Group by FMC.product_code, PRD.product
order by 3 desc
) AS T1
UNION 
select * from
(
select TOP 1 FMC.product_code, PRD.product, MIN(manufacturing_cost) AS 'manufacturing_cost'
from [gdb023].[fact_manufacturing_cost] (NOLOCK) FMC
INNER JOIN [gdb023].[dim_product] (NOLOCK) PRD ON PRD.product_code = FMC.product_code
Group by FMC.product_code, PRD.product
order by 3 
) AS T2
Order by 3 desc



-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 
-- and in the Indian market. The final output contains these fields : customer_code, customer, average_discount_percentage


SELECT TOP 5 CUS.customer_code, CUS.customer, AVG(pre_invoice_discount_pct) AS 'average_discount_percentage'
FROM gdb023.dim_customer (NOLOCK) CUS
INNER JOIN gdb023.fact_pre_invoice_deductions (NOLOCK) FPID ON FPID.customer_code = CUS.customer_code
WHERE
	fiscal_year = 2021
AND market = 'India'
GROUP BY CUS.customer_code, CUS.customer
ORDER BY 3 desc


-- 7. Get the complete report of the Gross sales amount for the customer “AtliqExclusive” for each month. 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.
-- The final report contains these columns: Month, Year, Gross sales Amount


;WITH CTE1 AS (
select 
	DATEPART(MONTH,FSM.[date]) AS 'Month',
	DATENAME(month,FSM.[date]) AS 'Month Name',
	DATEPART(year,FSM.[date]) AS 'Year',
	SUM((gross_price * sold_quantity)) AS 'Gross sales Amount'
from [gdb023].[dim_customer] (nolock) CUS
INNER JOIN [gdb023].[fact_sales_monthly] (nolock) FSM ON FSM.customer_code = CUS.customer_code
INNER JOIN [gdb023].[fact_gross_price] (nolock) FGP ON FGP.product_code = FSM.product_code
WHERE
	CUS.customer = 'Atliq Exclusive'
Group By DATEPART(MONTH,FSM.[date]), DATENAME(month,FSM.[date]), DATEPART(year,FSM.[date]) 
)
select [Month Name], [Year], [Gross sales Amount] from CTE1
Order by [Year], [Month]



-- 8. In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields : Quarter, total_sold_quantity, sorted by : the total_sold_quantity

select 
	DATEPART(quarter,[date]) AS 'Quarter',	
	SUM(sold_quantity) AS 'total_sold_quantity'	
from [gdb023].[fact_sales_monthly] (NOLOCK)
where fiscal_year = 2020
group by  DATEPART(quarter,[date])
order by 2 desc



-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
-- The final output contains these fields : channel, gross_sales_mln, percentage



select channel, SUM((gross_price * sold_quantity)) AS 'gross_sales_mln'
into #TT1
from [gdb023].[dim_customer] (nolock) CUS
INNER JOIN [gdb023].[fact_sales_monthly] (nolock) FSM ON FSM.customer_code = CUS.customer_code
INNER JOIN [gdb023].[fact_gross_price] (nolock) FGP ON FGP.product_code = FSM.product_code
WHERE
	FSM.fiscal_year = 2021
Group by channel

Declare @TotalSales BIGINT;
select @TotalSales = SUM(gross_sales_mln) from #TT1

select channel, gross_sales_mln, ROUND(((gross_sales_mln * 100) / @TotalSales),2) AS 'percentage'
from #TT1
order by 2 desc

drop table #TT1



-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields  : division, product_code, product, total_sold_quantity, rank_order


;WITH CTE_T1 AS(
SELECT  
	division, PRD.product_code, product, SUM(sold_quantity) AS 'total_sold_quantity',
	ROW_NUMBER() OVER (PARTITION BY division order by SUM(sold_quantity) desc) AS 'rank_order'
FROM [gdb023].[dim_product] (NOLOCK) PRD
INNER JOIN [gdb023].[fact_sales_monthly] (NOLOCK) FSM ON FSM.product_code = PRD.product_code
WHERE
	fiscal_year = 2021
GROUP BY division, PRD.product_code, product
) 
SELECT * FROM CTE_T1
WHERE rank_order < 4
--Inspecting Data
select * from [dbo].[sales_data]

--Checking unique values
select distinct STATUS from [dbo].[sales_data]
select distinct YEAR_ID from [dbo].[sales_data]
select distinct PRODUCTLINE from [dbo].[sales_data]
select distinct COUNTRY from [dbo].[sales_data]
select distinct DEALSIZE from [dbo].[sales_data]
select distinct TERRITORY from [dbo].[sales_data]

select distinct MONTH_ID from [dbo].[sales_data]
where YEAR_ID=2003


--Analysis
--Lets start by grouping sales by productline

select PRODUCTLINE,SUM(SALES) Revenue
from [dbo].[sales_data]
group by PRODUCTLINE
ORDER BY 2 desc



select YEAR_ID,SUM(SALES) Revenue
from [dbo].[sales_data]
group by YEAR_ID
ORDER BY 2 desc


select DEALSIZE,SUM(SALES) Revenue
from [dbo].[sales_data]
group by DEALSIZE
ORDER BY 2 desc


--What was the best month for sales in a specific year?How much was earned that month?

select MONTH_ID,sum(sales) Revenue,count(ORDERNUMBER) Frequency
FROM [dbo].[sales_data]
where YEAR_ID=2004
GROUP BY MONTH_ID
ORDER BY 2 DESC

--November seems to be the best month,what product do they sell in november,classic i believe

select MONTH_ID,PRODUCTLINE,sum(sales) Revenue,count(ORDERNUMBER) Frequency
FROM [dbo].[sales_data]
where YEAR_ID=2004 and MONTH_ID=11
GROUP BY MONTH_ID,PRODUCTLINE
ORDER BY 3 DESC


---Who is our best customer (this could be best answered with RFM)
DROP TABLE IF EXISTS #rfm
;with rfm as
(
   select 
       CUSTOMERNAME,
       sum(sales) MonetaryValue,
       avg(sales) AvgMonetaryValue,
       count(ORDERNUMBER) Frequency,
       max(ORDERDATE) last_order_date,
       (select max(ORDERDATE) from [dbo].[sales_data]) max_order_date,
       DATEDIFF(DD,max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data])) Recency
    from [dbo].[sales_data]
    group by CUSTOMERNAME
),
rfm_calc as
(
	select r.*,
	   NTILE(4) OVER (ORDER BY Recency desc) rfm_recency,
	   NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
	   NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
	from rfm r
)
select
    c.*,rfm_recency+rfm_frequency+rfm_monetary as rfm_cell,
    cast(rfm_recency as varchar)+cast(rfm_frequency as varchar)+cast(rfm_monetary as varchar)rfm_cell_string
into #rfm
from rfm_calc c


select CUSTOMERNAME,rfm_recency,rfm_frequency,rfm_monetary ,
	case
		when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then 'lost_customers' --lost customers
		when rfm_cell_string in (133,134,143,244,334,343,344,144) then 'slipping away,cannot lose' --(Big spenders who buy often & recently,but at low price points) 
		when rfm_cell_string in (311,411,331) then 'new customers' 
		when rfm_cell_string in (222,223,233,322) then 'potential churners' 
		when rfm_cell_string in (323,333,321,422,332,432) then 'Active' --(customers who buy often & recently,but at low price points)
		when rfm_cell_string in (433,434,443,444) then 'loyal'
	end rfm_segment
from #rfm


--what product are most often sold together
--select * from [dbo].[sales_data] where ORDERNUMBER=10411
 

 select distinct OrderNumber,STUFF(
	 (select ',' + PRODUCTCODE
	 from [dbo].[sales_data] p
	 where ORDERNUMBER in 
		(
			select ORDERNUMBER
			from 
			(
				select ORDERNUMBER,COUNT(*) rn
				from [dbo].[sales_data]
				where STATUS='Shipped'
				group by ORDERNUMBER
			)m
			where rn=2
		)
		and p.ORDERNUMBER=s.ORDERNUMBER
		for xml path (''))
		,1,1,'') productcodes

from [dbo].[sales_data] s
order by 2 desc
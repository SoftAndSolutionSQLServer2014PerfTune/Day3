select
		distinct																					-- Step 6	DISTINCT modifier
		top 1																						-- Step 8	TOP N modifier
	  p.[Name]								as [City State]											-- Step 5	Column list
	, avg(sod.UnitPrice)					as [Avg Unit Price]
from																								-- Step 1	FROM clause
	Production.Product						as p													
	inner join Sales.SalesOrderDetail   	as sod		on p.ProductID = sod.ProductID			
where																								-- Step 2	WHERE clause
	p.Color	is not null
group by																							-- Step 3	GROUP BY clause
	p.[Name]
having																								-- Step 4	HAVING clause
	count(*) > 1
order by																							-- Step 7	ORDER BY clause
	[Avg Unit Price]	desc
;
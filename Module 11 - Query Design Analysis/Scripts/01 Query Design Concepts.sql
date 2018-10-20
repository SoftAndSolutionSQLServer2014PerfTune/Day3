use AdventureWorks;
go

-- Enable Time and IO Statistics
set statistics time on;
set statistics io on;
go

-- Clear Buffer and Procedure Caches
checkpoint;
go
dbcc dropcleanbuffers;
dbcc freeproccache;
go


-- Rule #1: Operate on  Small Result Sets
--		Limit columns in select list
--		Use selective where clauses to limit rows


-- Rule #2: Avoid Nonsargable Search Conditions
--		Sargable means Search ARGument ABLE
--		Sargable = > < <= >= between like 'char%'
--		Non-Sargable <> != !> !< not in or like '%char'

-- Run both queries, notice Execution Plans look the same
-- But check out the IO stats, 5 Logical Reads vs 17 Logical Reads (4 Scans because in operator causes or statements)
select *
from Sales.SalesOrderDetail 
where SalesOrderID in (51825, 51826, 51827, 51828);

select *
from Sales.SalesOrderDetail 
where SalesOrderID between 51825 and 51828;


-- Rule #3: Avoid Math on Columns in the Where Clause

-- Run both queries, notice Execution Plans and query costs are different
select *
from Purchasing.PurchaseOrderHeader
where PurchaseOrderID * 2 = 3400;			-- Math is on column side, so can do Index Seek

select *
from Purchasing.PurchaseOrderHeader
where PurchaseOrderID = 3400 / 2;			-- Math is not on column side, its on literal side


-- Rule #4: Avoid Functions on Columns in the Where Clause

-- Run both queries, notice Execution Plans are different
create index IX_SalesOrderHeader_OrderDate on Sales.SalesOrderHeader(OrderDate);

select *
from Sales.SalesOrderHeader
where Year(OrderDate) = '2014';

select *
from Sales.SalesOrderHeader
where OrderDate >= '2014-01-01' and OrderDate <= '2014-12-31';

drop index IX_SalesOrderHeader_OrderDate on Sales.SalesOrderHeader;


-- Rule #5: Indexes good for many things
select ProductID, Color
from Production.Product
order by Color;

select COUNT(*), Color
from Production.Product
group by Color;

select MIN(color)
from Production.Product;

go
create index IX_Product_Color on Production.Product(Color);
go

select ProductID, Color
from Production.Product
order by Color;

select COUNT(*), Color
from Production.Product
group by Color;

select MIN(color)
from Production.Product;

drop index IX_Product_Color on Production.Product;


-- Disable Time and IO Statistics
set statistics time off;
set statistics io off;
go
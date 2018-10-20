use AdventureWorks;
go


-- Clear Buffer and Procedure Caches
checkpoint;
go
dbcc dropcleanbuffers;
dbcc freeproccache;
go


-- Create Schema
create schema Test;
go

-- Create Table
select * 
into Test.Product
from Production.Product;
go

-- Create Procedure
create procedure Test.spGetProducts
as
select ProductID, [Name], ListPrice from Test.Product;
go

exec Test.spGetProducts;
go


-- Check out Creation Time and Execution Count for SProc
select creation_time, execution_count, [text]
from sys.dm_exec_query_stats cross apply sys.dm_exec_sql_text(plan_handle);


-- Adding Index (Even one that didn't effect Sproc) Causes Recompile
create index IX_Product_ProductNumber on Test.Product(ProductNumber);
go

exec Test.spGetProducts;
go

-- Verify Recompile
select creation_time, execution_count, [text]
from sys.dm_exec_query_stats cross apply sys.dm_exec_sql_text(plan_handle);
go


-- Cleanup
drop table Test.Product;
drop procedure Test.spGetProducts;
drop schema Test;


-- Causes of Recompiles
------------------------

--The schema of regular tables, temporary tables, or views referred to in the stored
--procedure statement have changed. Schema changes include changes to the metadata of
--the table or the indexes on the table.

--Bindings (such as defaults) to the columns of regular or temporary tables have changed.

--Statistics on the table indexes or columns have changed past a certain threshold.

--An object did not exist when the stored procedure was compiled, but it was created
--during execution. 

--The execution plan was aged and deallocated.
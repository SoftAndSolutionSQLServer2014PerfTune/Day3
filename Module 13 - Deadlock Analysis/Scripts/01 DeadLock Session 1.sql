use AdventureWorks;

select @@SPID;


-- DeadLock Example
-- Rollback All Transactions
-- Run This Update Transaction 
begin transaction
	update Production.Product						
	set ListPrice = 1;

-- Next Run Update Transaction in Other User Script


-- Now Run this Update Transaction one more time to cause a deadlock
begin transaction
	update Production.Product						
	set ListPrice = 3;
	
	
-- Rollback All Transactions
rollback;

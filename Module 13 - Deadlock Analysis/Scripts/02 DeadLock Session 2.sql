use AdventureWorks;

select @@SPID;

-- Other User Script
begin transaction
	update Production.Product						
	set ListPrice = 2;

-- Now return to 01 Deadlock Session 1 script


--commit;
rollback;

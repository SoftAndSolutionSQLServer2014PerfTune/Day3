use AdventureWorks;

select @@SPID;

-- Other User Script
begin transaction
	update Production.Product						
	set ListPrice = 1;

select Name, ListPrice from Production.Product;

--commit   
rollback;

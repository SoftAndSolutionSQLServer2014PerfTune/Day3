use Adventureworks;

-- Turn on Actual Execution Plan (Ctrl-M)


-- Declare and set variables for query statement and parameter list
--		Note the query was chosen to show bad parameter sniffing issues
declare @Query nvarchar(max), @ParamList nvarchar(max);
set @Query = N'select * from Person.Address where StateProvinceID=@StateProvinceID';
set @ParamList = N'@StateProvinceID int';


-- sp_executesql
--		Compare Estimated / Actual Number of Rows 
--		Bad parameter sniffing
exec sp_executesql @Query, @ParamList, @StateProvinceID = 32;
exec sp_executesql @Query, @ParamList, @StateProvinceID = 9;


-- Prepare & Execute Model
-- sp_prepare
declare @PreparedHandle int;  
exec sp_prepare @PreparedHandle output, @ParamList, @Query;  

-- sp_execute
--		Compare Estimated / Actual Number of Rows 
--		Where does 265.054 come from?
exec sp_execute @PreparedHandle, @StateProvinceID = 32;  
exec sp_execute @PreparedHandle, @StateProvinceID = 9;  

--		265.054 is the density estimate for the table
--		Basically the average distribution for the table instead the one for the parameter value
dbcc show_statistics ('Person.Address', IX_Address_StateProvinceID);

--		265.054 = 19614 Rows * 0.01351351 All density
select 19614 * 0.01351351 as [Density Estimate];

-- Cleanup 
exec sp_unprepare @PreparedHandle;

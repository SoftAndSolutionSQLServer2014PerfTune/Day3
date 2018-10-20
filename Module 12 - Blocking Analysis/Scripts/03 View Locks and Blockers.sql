use AdventureWorks;

-- View Blockers
select * 
from sys.dm_exec_requests
where blocking_session_id <> 0;


-- View Blockers and Wait
select session_id, wait_duration_ms, wait_type, blocking_session_id 
from sys.dm_os_waiting_tasks 
where blocking_session_id <> 0;


-- View Blockers again
select t1.resource_type, t1.resource_database_id, t1.resource_associated_entity_id, 
	   t1.request_mode, t1.request_session_id, t2.blocking_session_id
from sys.dm_tran_locks as t1
	join sys.dm_os_waiting_tasks			as t2				on t1.lock_owner_address = t2.resource_address;
        
        
-- Tried and True ways of seeing Locks
exec sp_lock;
exec sp_who2;


-- DMV View of Locks, Objects, and Session Info
select db_name(dtl.resource_database_id)		as DBName
	, o.Name									as LockedObjectName
	, dtl.resource_type							as LockedResource
	, dtl.request_mode							as LockType
	, dtl.request_session_id					as SPID
	, des.login_name							as LoginName
	, des.host_name								as HostName
from sys.dm_tran_locks							as dtl
	join sys.partitions							as p					on dtl.resource_associated_entity_id = p.hobt_id
	join sys.objects							as o					on p.object_id = o.object_id
	join sys.dm_exec_sessions					as des					on dtl.request_session_id = des.session_id 
where resource_database_id = DB_ID(N'AdventureWorks') 
	and request_session_id = 57;

USE [SME_1]
GO

/****** Object:  Trigger [dbo].[alarm_dalje_nga_zona]    Script Date: 10/21/2018 12:33:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Meri Manaj>
-- Create date: <28-04-2017>
-- Description:	<per hedhjen ne tabelen SME_Loge1 dhe shtimin e alarmeve>
-- =============================================
ALTER TRIGGER [dbo].[alarm_dalje_nga_zona]
   ON  [dbo].[SME_Loge]
   AFTER  INSERT
AS
SET NOCOUNT ON;

-- *** Store Data from Inserted Table ***
-- Declare Variables
declare @_Kod_Pajisje			varchar(20);	
declare @_idSME_Loge			numeric;	
declare @_idSME_Loge1			numeric;
declare @_valid					int=1;	
declare @_data					datetime;	
declare @_gjeometria			geometry;
declare @_bateria				int;
declare @_lartesia				numeric;
declare @_alarmi				varchar(50);
declare @_home_status			varchar(50);
declare @_status_rripi_shtuar	varchar(50)='';

-- Set Variables with Data from Inserted Table
--		Note:  Better one SELECT statement then many individual SELECT statements
select 
	@_Kod_Pajisje				= [Kodi_pajisjes], 
	@_idSME_Loge				= [IDSME_Loge],
	@_valid						= [Valid],
	@_data						= [Data],
	@_gjeometria				= [Koordinata],
	@_bateria					= [Bateria],
	@_lartesia					= [Lartesia],
	@_alarmi					= [Alarmi],
	@_home_status				= [Home_status],
	@_status_rripi_shtuar		= [Statusi_rripit]
from inserted;


-- *** Check Equipment ID is valid ***
-- Declare Variables
declare @_table_idPajisje		table (ID_pajisja numeric);
declare @_idPajisje				numeric=0;
declare @_nr_daljesh			int=0;

-- Check @IDEquipment is Valid where Code column = @Code_Equipment
select 
	@_idPajisje					= [ID]  
from 
	[SME_1].[dbo].[SME_Pajisja] 
where 
	[Kodi]						= @_Kod_Pajisje;

-- If Invalid, add default values
if @_idPajisje is null or @_idPajisje < 1		
begin
	-- Insert Data
	insert into [dbo].[SME_Pajisja] 
		([Kodi], [Nr_tel], [IMEI], [ModifiedOn], [ModifiedIP], [Password], [perfunduar_konfigurimi], [ModifiedBy])
	output inserted.ID into @_table_idPajisje
    values (@_Kod_Pajisje, null, @_Kod_Pajisje, sysdatetime(), '1.1.1.1', '123456', 2, null);

	select @_idPajisje=ID_pajisja from @_table_idPajisje;
end;


-- *** Check @IDEquipment is Valid where Code column = @Code_Equipment ***
-- Declare Variables
declare @_distanca				int=null;
declare @_zone_ndaluar			int=0;
declare @_gjeometria_zones		geometry=null;
declare @_gjeometria_qender		geometry=null;
declare @vektori_gjeometrise	table (gjeometria geometry,ndaluar int);

insert into @vektori_gjeometrise 
	-- ******************************* 
	-- TODO:  Change to a better query
	-- *******************************
	select top 1 
		  SME_zona.geometry
		, SME_zona.zone_ndaluar 
	from 
		SME_zona
		, SME_Zona_teMbikqyrur
		, SME_Te_Mbikqyrur 
	where 
			SME_Te_Mbikqyrur.id_Pajisja=@_idPajisje 
		and SME_Te_Mbikqyrur.ID=SME_Zona_teMbikqyrur.ID_te_mbikqyrur 
		and SME_Zona_teMbikqyrur.IDZona=SME_zona.IDZona and SME_zona.Valid=1 
		and SME_Zona_teMbikqyrur.Valid=1;

select @_gjeometria_zones=gjeometria from @vektori_gjeometrise;
select @_zone_ndaluar=ndaluar from @vektori_gjeometrise;


-- If a zone is configured for this device then geometry control is performed
if @_gjeometria_zones is not null 
begin
	declare @_gjeometria_qender_te_reja geometry=@_gjeometria_zones.STCentroid();
	SELECT @_gjeometria_qender=dbo.random_polygon(@_gjeometria_qender_te_reja);
	--set @_gjeometria_qender=@_gjeometria_zones.STCentroid();
	if @_home_status is null 
	begin
		SELECT @_distanca=ROUND(@_gjeometria.STDistance(@_gjeometria_zones)*111195,0);
		if @_distanca<=30 
			begin
				if @_zone_ndaluar<>1 
				begin
					--merret si koordinat qendra e zones
					set @_gjeometria=@_gjeometria_qender;
					set @_distanca=0;
				end
			end
		else
		if @_zone_ndaluar<>1 
		begin
			--do te kontrollohet kordinata e fundit (max) per te pare e sajta eshte jane zone dhe te shtohet alarmi
			--merret numri i daljeve nga zona te kordinates se fundit te shtuar per kete pajisje
			select @_nr_daljesh=Nr_daljesh FROM SME_Loge	WHERE SME_Loge.IDSME_Loge= (select max(A.IDSME_Loge) FROM SME_Loge as A WHERE A.Kodi_pajisjes=@_Kod_Pajisje and IDSME_Loge<@_idSME_Loge)

			--select @_nr_daljesh=Nr_daljesh FROM SME_Loge	WHERE SME_Loge.IDSME_Loge= (select max(A.IDSME_Loge) FROM SME_Loge as A WHERE A.Kodi_pajisjes=@_Kod_Pajisje)
			set @_nr_daljesh=@_nr_daljesh+1;
			--nese eshte me i vogel se tre dalje nga zona rradhazi do te thote se eshte dalje e rrem
			if @_nr_daljesh<=3
			begin
				set @_gjeometria=@_gjeometria_qender;
				set @_distanca=0;
			end
		end
	end
	else
	--eshte pajisja e re
	begin
		--Nese ka levizur pajisja behet update flagu
		if (@_alarmi='Move TAG')
		begin
			Update SME_Pajisja set flag=1 where imei=@_Kod_Pajisje;
		end
		else
		begin
			declare @_flag int
			Select @_flag=flag from SME_Pajisja where imei=@_Kod_Pajisje
			--nese flag nuk eshte moving, kontrollohet home status
			if (@_flag=2)
			begin
			--nese tag nuk eshte moving, kontrollohet home status
				if (@_home_status=1)
				begin 
					if @_zone_ndaluar<>1 
					begin
						--merret si koordinat qendra e zones
						set @_gjeometria=@_gjeometria_qender_te_reja;
						set @_distanca=0;
					end
				end
			end
		end
	end
end
  
  
ALTER PROC dbo.rpt_BangCongHangThang_16052022 
--@condition VARCHAR(MAX) =" and (at.CutOffDurationID like N'%8520A005-25B2-4583-84C9-F87E81D9FD71%' ) ",  
@condition VARCHAR(MAX) =" and (at.CutOffDurationID like N'%62BAFF6E-1045-4D11-B89F-84B2527F04E2%' and hp.Codeemp ='01441') ",  
--@condition VARCHAR(MAX) =" and (at.CutOffDurationID like N'%99E3752E-CC9C-4CA3-A9A9-BB842B092039%') ",  
@PageIndex INT = 1,  
@PageSize INT = 3000,  
@Username VARCHAR(100) = 'support'  
AS  
BEGIN  

DECLARE @str NVARCHAR(MAX)
DECLARE @countrow INT
DECLARE @row INT
DECLARE @index INT
DECLARE @ID NVARCHAR(500)
DECLARE @TempID NVARCHAR(MAX)
DECLARE @TempCondition NVARCHAR(MAX)
DECLARE @Top VARCHAR(20) = ' '
DECLARE @CurrentEnd BIGINT
DECLARE @Offset TINYINT

IF LTRIM(RTRIM(@Condition)) = '' OR @Condition IS NULL
BEGIN
		SET @Top = ' top 0 ';
		SET @condition =  ' and (at.CutOffDurationID like N''%8520A005-25B2-4583-84C9-F87E81D9FD71%'') and (at.ProfileID in (''4A7A65A7-83D5-42A1-ADF0-9AB6CE537319'')) '
END;


-- Condition
DECLARE @CutOffDurationID varchar(200) = ''
DECLARE @CutOffDurationID_ID UNIQUEIDENTIFIER
-- xử lý tách dk
set @str = REPLACE(@condition,',','@')
set @str = REPLACE(@str,'and (',',')
SELECT ID into #tableTempCondition FROM SPLIT_To_NVARCHAR (@str)
set @row = (SELECT count(ID) FROM SPLIT_To_NVARCHAR (@str))
set @countrow = 0
set @index = 0
WHILE @row > 0
BEGIN
	set @index = 0
	set @ID = (select top 1 ID from #tableTempCondition)
	set @tempID = replace(@ID,'@',',')

	set @index = charindex('at.CutOffDurationID',@tempID,0) 
	if(@index > 0)
	begin
		set @tempCondition = 'and ('+@tempID
		SET @CutOffDurationID = REPLACE(@tempCondition, 'and (at.CutOffDurationID like N', '' )
		set @CutOffDurationID = REPLACE(@CutOffDurationID,')','')
		set @CutOffDurationID = REPLACE(@CutOffDurationID,'%','')
	END

	DELETE #tableTempCondition WHERE ID = @ID
	SET @row = @row - 1

END

SET @CutOffDurationID_ID = REPLACE(@CutOffDurationID,'''','')


DECLARE @Count INT = 1;
declare @ListCol varchar(max);
declare @ListAlilas varchar(max);
declare @SumWorkDate varchar(max);

DECLARE @DateStart date,  @DateEnd date
SELECT @DateStart = DateStart, @DateEnd = DateEnd from Att_CutOffDuration WHERE IsDelete is NULL AND ID = @CutOffDurationID_ID

DECLARE @FirstDay DATE = @DateStart;
while @FirstDay <= @DateEnd
        begin
            set @ListCol = coalesce(@ListCol + ',', '') + quotename(@FirstDay);
            set @ListAlilas = coalesce(@ListAlilas + ',', '') + quotename(@FirstDay) + ' as D' + convert(varchar(10), @Count);
            set @SumWorkDate = coalesce(@SumWorkDate + '+', '') + 'ISNULL(' + QUOTENAME(@FirstDay) + ',0)'
            set @FirstDay = dateadd(day, 1, @FirstDay);
            SET @Count += 1;
        END;



--SELECT @DateStart, @DateEnd
--SELECT @ListCol
--SELECT @ListAlilas
--SELECT @SumWorkDate

DECLARE @query VARCHAR(MAX)  
DECLARE @query2 VARCHAR(MAX) 
DECLARE @query3 VARCHAR(MAX) 
DECLARE @querycondition VARCHAR(MAX)  
DECLARE @queryPageSize VARCHAR(MAX)  


--print @condition return  
SET @query = ' 
declare @DateStart date = ''' + convert(varchar(20), @DateStart, 111) + ''';
declare @DateEnd date = ''' + convert(varchar(20), @DateEnd, 111) + ''';

DECLARE @tblPermission TABLE (id uniqueidentifier primary key )  
INSERT INTO @tblPermission EXEC Get_Data_Permission_New ''' + @Username + ''', ' + '''Hre_Profile''' + '  

SELECT		'+@Top+' at.*
INTO		#Att_AttendanceTable
FROM		Att_AttendanceTable at
INNER JOIN  @tblPermission tps 
	ON		tps.ID = at.ProfileID
INNER JOIN	Hre_Profile hp
	ON		hp.ID = at.ProfileID
LEFT JOIN	Cat_OrgStructure cos
	ON		cos.id=at.OrgStructureID
WHERE		at.IsDelete IS NULL
	AND		hp.IsDelete IS NULL
			' + @condition + '

SELECT		at.ProfileID,ati.* 
INTO		#Att_AttendanceTableItem
FROM		#Att_AttendanceTable at
INNER JOIN	Att_AttendanceTableItem ati ON at.id = ati.AttendanceTableID

---- Cong Thieu/ Cong thua
SELECT		at.ProfileID,at.ID AS AttendanceTableID , isnull(CongThua.ActualHours,0) - isnull(CongThieu.ActualHours,0) as CongThua,concat(CongThieu.Note, CongThua.Note)as Note 
INTO		#CongThua
FROM		#Att_AttendanceTable at

OUTER APPLY (select		TOP(1) ProfileID,cj.Code,ap.Note,ap.WorkDate,ap.ActualHours 
			from		Att_ProfileTimeSheet ap
			left join	Cat_JobType cj on cj.id=ap.JobTypeID  
			where		EXISTS  (select id from Cat_JobType cj where cj.Code in (''CongThieu'') AND cj.ID = ap.JobTypeID )
				and		ap.IsDelete is null
				AND		ap.profileid = at.profileid and ap.WorkDate Between at.DateStart and at.DateEnd
			ORDER BY	ap.DateUpdate DESC
			) CongThieu 
OUTER APPLY (select		TOP(1) ProfileID,cj.Code,ap.Note,ap.WorkDate,ap.ActualHours 
			from		Att_ProfileTimeSheet ap
			left join	Cat_JobType cj on cj.id=ap.JobTypeID  
			where		EXISTS  (select id from Cat_JobType cj where cj.Code in (''CongThua'') AND cj.ID = ap.JobTypeID )
				and		ap.IsDelete is null
				AND		ap.profileid = at.profileid and ap.WorkDate Between at.DateStart and at.DateEnd
			ORDER BY	ap.DateUpdate DESC
			) CongThua

---- TienMuon
select		ProfileID,AttendanceTableID,sum(TienPhatMuon) as Tien_Muon, sum(SoLanMuon) as SL_MuonSom
INTO		#TienMuon
from   
			(select		at.ProfileID,ati.AttendanceTableID
						,case  
						when ati.LateEarlyMinutes <=3 then 0  
						when ati.LateEarlyMinutes >3 and ati.LateEarlyMinutes <10  then 30000  
						when ati.LateEarlyMinutes >=10 and ati.LateEarlyMinutes <30 then 50000  
						when ati.LateEarlyMinutes >=30  then 100000  
						else 0  
						end as TienPhatMuon  
						,case when ati.LateEarlyMinutes >3 then 1 else 0 
						end as SoLanMuon  
			from		#Att_AttendanceTable at
			left join	Att_AttendanceTableItem ati on ati.AttendanceTableID = at.ID
			) aaa 
group by	ProfileID,AttendanceTableID

	'
SET @query2 = ' 

SELECT		ati.ProfileID,ati.AttendanceTableID, ati.WorkDate
			,case  
			when cs1.Code=''KS_TVU1'' then ati.WorkPaidHours/8  
			when ati.WorkHoursShift2 >0 then  ati.WorkHoursShift1/nullif(cs1.StdWorkHours,0)*1.0 +ati.WorkHoursShift2/nullif(cs2.StdWorkHours,0)*1.0  
			else  ati.WorkPaidHours/nullif(cs1.StdWorkHours ,0)  
			end  as Cong
INTO		#KQ_Tmp_Item
FROM		#Att_AttendanceTableItem ati
LEFT  JOIN	cat_shift cs1 ON cs1.id = ati.ShiftID
LEFT  JOIN	cat_shift cs2 ON cs2.id = ati.Shift2ID

SELECT		ProfileID as ProfileID_pivot,AttendanceTableID AS AttendanceTableID_pivot, ' + @ListAlilas + ', ' +ISNULL(@SumWorkDate,0)+' AS CongThucTe
INTO		#KQ_Tmp_Item_pivot
FROM		(SELECT profileid,AttendanceTableID,WorkDate,Cong FROM #KQ_Tmp_Item ) D
PIVOT 
			(
				SUM(Cong) for WorkDate in (' + @ListCol + ')
			 ) as pvtbl

SELECT		at.ProfileID,hp.CodeEmp,hp.ProfileName,cp.PositionName,cos.OrgStructureName  
			,hp.DateQuit,at.MonthYear, at.ID AS AttendanceTableID,at.CutOffDurationID,cos.OrderNumber,at.StdWorkDayCount
			,kqtip.*
			,OTT as OT,
			CASE WHEN cl1.Code IS NOT NULL THEN ISNULL(at.LeaveDay1Days,0) ELSE 0 END +
			CASE WHEN cl2.Code IS NOT NULL THEN ISNULL(at.LeaveDay2Days,0) ELSE 0 END +
			CASE WHEN cl3.Code IS NOT NULL THEN ISNULL(at.LeaveDay3Days,0) ELSE 0 END +
			CASE WHEN cl4.Code IS NOT NULL THEN ISNULL(at.LeaveDay4Days,0) ELSE 0 END +
			CASE WHEN cl5.Code IS NOT NULL THEN ISNULL(at.LeaveDay5Days,0) ELSE 0 END +
			CASE WHEN cl6.Code IS NOT NULL THEN ISNULL(at.LeaveDay6Days,0) ELSE 0 END
			as CongKhac
			,cthua.CongThua, cthua.Note
			,case  when at.LeaveDay2Type in (select id from Cat_LeaveDayType where Code=''P'') then at.LeaveDay2Days  
				when at.LeaveDay1Type in (select id from Cat_LeaveDayType where Code=''P'') then at.LeaveDay1Days  
				else 0 
			end as P_DAY  
			,tm.SL_MuonSom, MissInOut.SL_ThieuInOut,at.ActualHoursAllowance as TienTruc  
			,at.DateStart,at.DateEnd,al.DateStart as BatDauTS,al.DateEnd as KetThucTS  
			,ThieuInOut,MuonSom,Tien_Muon, ale.Days as PhepUng
			,PhatKhac.AmountOfFine as TienPhatKhac,ConCat(PhatKhac.Notes,VPTS.Notes) as LyDoPhat  
			,VPTS.AmountOfFine as ViPhamThaiSan,VPTS.NameEntityName,hr1.RewardValue, hr1.Reason as RewardReason,ac.InitAvailable as TongCongThua  
			,KoDK_CoAn.SL1,CoDK_KhongAn.SL2,KoDK_CoAn.DienGiai1,CoDK_KhongAn.DienGiai2
			,(ISNULL(KoDK_CoAn.SL1,0) + ISNULL(CoDK_KhongAn.SL2,0)) * 50000 AS TienBoCom
			,ISNULL(MissInOut.SL_ThieuInOut,0) * 30000 AS QT1C
			,NULL AS "at.CutOffDurationID", NULL AS "at.ProfileID", NULL AS "cos.OrderNumber"
			,ROW_NUMBER() OVER ( ORDER BY CodeEmp asc) as RowNumber 
INTO		#KQ_Tmp
from		#Att_AttendanceTable at  
OUTER APPLY (
			SELECT		TOP (1) ac.InitAvailable
			FROM		Att_CompensationConfig ac 
			WHERE		ac.profileid=at.profileid 
				AND		ac.MonthBeginInYear = at.MonthYear AND ac.IsDelete IS NULL
			ORDER BY	ac.DateUpdate desc
			) ac
left join	Hre_Reward hr1 on hr1.ProfileID=at.ProfileID and at.MonthYear=hr1.DateOfEffective and hr1.IsDelete is null   
LEFT join	Hre_Profile hp on hp.ID=at.ProfileID and hp.isdelete is null  
left join	Att_AnnualLeaveExtend ale on ale.profileid=at.profileid and at.DateStart>=ale.monthstart and at.dateend<=ale.monthend and ale.isdelete is null  
left join	Cat_LeaveDayType cl1 on cl1.id=at.LeaveDay1Type and cl1.PaidRate=1
left join	Cat_LeaveDayType cl2 on cl2.id=at.LeaveDay2Type and cl2.PaidRate=1
left join	Cat_LeaveDayType cl3 on cl3.id=at.LeaveDay3Type and cl3.PaidRate=1
left join	Cat_LeaveDayType cl4 on cl4.id=at.LeaveDay4Type and cl4.PaidRate=1
left join	Cat_LeaveDayType cl5 on cl5.id=at.LeaveDay5Type and cl5.PaidRate=1
left join	Cat_LeaveDayType cl6 on cl6.id=at.LeaveDay6Type and cl6.PaidRate=1

--Vi pham thai san và tien phat khac  
OUTER APPLY (select		TOP(1) hd.ProfileID,hd.DateOfEffective,cn.NameEntityName,hd.AmountOfFine,hd.Notes,DisciplineResonID,DateEndOfViolation 
			from		Hre_Discipline hd  
			left join	Cat_NameEntity cn on cn.ID=hd.DisciplineResonID and NameEntityType=''E_DISCIPLINE_REASON''  
			where		hd.IsDelete is null and cn.Code = 2
				AND		at.profileid = hd.profileid and at.DateEnd >=hd.DateOfEffective and hd.DateEndOfViolation >= at.DateStart
			ORDER BY	hd.DateUpdate DESC
			) PhatKhac  
  
OUTER APPLY (select		TOP(1) hd.ProfileID,hd.DateOfEffective,cn.NameEntityName,hd.AmountOfFine,hd.Notes,DisciplineResonID,DateEndOfViolation 
			from		Hre_Discipline hd  
			left join	Cat_NameEntity cn on cn.ID=hd.DisciplineResonID and NameEntityType=''E_DISCIPLINE_REASON''  
			where		hd.IsDelete is null and cn.Code = 1
				AND		at.profileid = hd.profileid and at.DateEnd >=hd.DateOfEffective and hd.DateEndOfViolation >= at.DateStart
			ORDER BY	hd.DateUpdate DESC
			) VPTS
  
 	'
SET @query3 = ' 
left join (	select		ProfileID,ati.AttendanceTableID,sum(ati.OvertimeHours/nullif(cs.StdWorkHours,0)) as OTT 
			from		#Att_AttendanceTableItem  ati
			left join	Cat_Shift cs on cs.id=ati.ShiftID  
			group by	ProfileID,ati.AttendanceTableID
			) OTT on OTT.AttendanceTableID = at.id
left JOIN	Cat_OrgStructure cos on cos.id=at.OrgStructureID  
LEFT JOIN	Cat_Position cp on cp.id =at.PositionID  
left join	Att_LeaveDay al on al.profileid=at.profileid and al.LeaveDayTypeID =(select id from Cat_LeaveDayType where Code=''TS'') and al.isdelete is null and at.monthyear>=al.datestart and at.monthyear<= al.dateend  

  
left join (	
			select		AttendanceTableID,count(id) as SL_ThieuInOut 
			from		#Att_AttendanceTableItem
			where		MissInOutReasonID not in (select id from Cat_TAMScanReasonMiss where Code in(''QCC01'',''QCC04'',''QCC05'',''QCC07''))
				and		MissInOutReasonID is not null
			group by	AttendanceTableID
			) MissInOut on at.id=MissInOut.AttendanceTableID  
left join (	
			select		AttendanceTableID as ID,STRING_AGG(concat(DATEPART(DAY,WorkDate),''/'',DATEPART(MONTH,WorkDate)),'','') MuonSom  
			from		#Att_AttendanceTableItem 
			where		IsDelete is null  
				and		AttendanceTableID in (select id from Att_AttendanceTable where IsDelete is null )
				and		LateEarlyMinutes>3  
			group by	AttendanceTableID
			) MS on at.id = MS.id  
left join (
			select		AttendanceTableID as ID,STRING_AGG(concat(DATEPART(DAY,WorkDate),''/'',DATEPART(MONTH,WorkDate)),'','') ThieuInOut  
			from		#Att_AttendanceTableItem  
			where		IsDelete is null  
				and		AttendanceTableID in (select id from Att_AttendanceTable where IsDelete is null )
				and		MissInOutReasonID is not null  
			group by	AttendanceTableID
			) IO on at.id = IO.id  
--Canteen  
left join (	
			select		cms.ProfileID,count (cms.id) SL1, STRING_AGG(concat('' '',DATEPART(DAY,TimeLog),''/'',DATEPART(MONTH,TimeLog)),'','') DienGiai1
			from		#Att_AttendanceTable at
			INNER JOIN	Can_MealRecord cms ON at.ProfileID = cms.ProfileID 
			left join	Can_MealBillEmployee cm on cm.ProfileID=cms.ProfileID and cm.DateMeal=DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) and cm.MealUnitID is null and cm.isdelete is null and (cm.Status is null or cm.Status<>''E_CANCEL'')  
			where		cms.IsDelete is null  
				and		cm.id is null and cms.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB'',''SANGLOCHM'')) 
				AND		cms.TimeLog BETWEEN @DateStart and @DateEnd
			group by cms.ProfileID,DATEADD(month, DATEDIFF(month, 0, TimeLog), 0)  
			) KoDK_CoAn on at.ProfileID=KoDK_CoAn.ProfileID
  
left join	(
			select		cm.ProfileID,count(cm.id) SL2,STRING_AGG(concat('' '',DATEPART(DAY,DateMeal),''/'',DATEPART(MONTH,DateMeal)),'','') DienGiai2  
			from		#Att_AttendanceTable at
			INNER join	Can_MealBillEmployee cm  ON at.ProfileID = cm.ProfileID 
			left join	(select	ProfileID,DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) as Ngay ,TimeLog,MachineCode  
						from	Can_MealRecord   
						where	IsDelete is null
						) QuetThe on QuetThe.ProfileID=cm.ProfileID and QuetThe.Ngay=cm.DateMeal  
			where		cm.IsDelete is null and QuetThe.TimeLog is null  and cm.MealUnitID is null  
				and		(cm.Status is null or cm.Status<>''E_CANCEL'') and cm.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB'',''SANGLOCHM''))  
				AND		cm.DateMeal BETWEEN @DateStart and @DateEnd
			group by cm.ProfileID, DATEADD(month, DATEDIFF(month, 0, cm.DateMeal), 0)  
			) CoDK_KhongAn on at.ProfileID=CoDK_KhongAn.ProfileID  

LEFT JOIN	#TienMuon tm
	ON		tm.ProfileID = at.ProfileID AND tm.AttendanceTableID = at.ID
LEFT JOIN	#CongThua cthua
	ON		cthua.ProfileID = at.ProfileID AND cthua.AttendanceTableID = at.ID
LEFT JOIN	#KQ_Tmp_Item_pivot kqtip ON at.ProfileID = kqtip.ProfileID_pivot and at.ID = kqtip.AttendanceTableID_pivot


SELECT		*,ISNULL(CongThucTe,0) + ISNULL(OT,0) + ISNULL(CongKhac,0) + ISNULL(CongThua,0)  AS ThangNay, ISNULL(CongThucTe,0) + ISNULL(OT,0) + ISNULL(CongKhac,0) + ISNULL(CongThua,0) - ISNULL(StdWorkDayCount,0) AS ThuaThieuCong
			, -1 * PhepUng AS TongCongDaUng, CASE WHEN SL_MuonSom > 5 OR SL_ThieuInOut > 5 THEN ''B'' ELSE ''A'' END AS XepLoai
INTO		#Results
FROM		#KQ_Tmp

'
  
SET @queryPageSize = '  ALTER TABLE #Results ADD TotalRow int 
declare @totalRow int  
SELECT @totalRow = COUNT(*) FROM #Results  
update #Results set TotalRow = @totalRow  
SELECT * FROM #Results WHERE RowNumber BETWEEN(' + CAST(@PageIndex AS VARCHAR) + ' -1) * ' + CAST(@PageSize AS VARCHAR) + ' + 1 AND(((' + CAST(@PageIndex AS VARCHAR) + ' -1) * ' + CAST(@PageSize AS VARCHAR) + ' + 1) + ' + CAST(@PageSize AS VARCHAR) + ') -
1  
DROP TABLE #Att_AttendanceTable,#Att_AttendanceTableItem, #CongThua, #TienMuon, #KQ_Tmp_Item, #KQ_Tmp_Item_pivot,#KQ_Tmp, #Results  


'  

PRINT (@query)  
PRINT (@query2)  
PRINT (@query3)  

PRINT (@queryPageSize) 
EXEC (@query + @query2 + @query3 + @queryPageSize)  

END  
  
-- rpt_BangCongHangThang_16052022
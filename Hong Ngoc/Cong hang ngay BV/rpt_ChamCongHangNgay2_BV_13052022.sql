

ALTER proc [dbo].[rpt_ChamCongHangNgay2_BV_13052022]
--@condition varchar(max) = " AND (aw.workdate >= '2022-01-01' and aw.workdate <= '2022-01-31' and hp.codeemp='02768')  ",
--@condition varchar(max) = " AND (aw.workdate between '2022-01-01' and '2022-01-31') and (hp.codeemp = '02768')  ",
@condition varchar(max) = " AND (aw.workdate between '2022-01-01' and '2022-01-31') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'support'
as
begin
declare @query varchar(max)
declare @query2 varchar(max)
declare @querycondition varchar(max)
declare @queryPageSize varchar(max)
declare @queryTop varchar(10) = '  '


if(@PageSize = 0) OR @condition = '' OR @condition = ' ' OR @condition IS NULL
begin
SET @queryTop = ' Top 0 '
SET @condition = ' AND (aw.workdate between ''2022-01-01'' and ''2022-01-31'') and (hp.codeemp in (''02768'')) '

END


DECLARE @str nvarchar(max)
DECLARE @countrow int
DECLARE @row int
DECLARE @index int
DECLARE @ID nvarchar(500)
DECLARE @TempID nvarchar(max)
DECLARE @TempCondition nvarchar(max)
DECLARE @Top varchar(20) = ' '
DECLARE @CurrentEnd bigint
DECLARE @Offset TINYINT

DECLARE @condition2 VARCHAR(500)
DECLARE @ProfileID VARCHAR(500) = ' '


-- xử lý tách dk
	set @str = REPLACE(@condition,',','@')
	set @str = REPLACE(@str,'and (',',')
	SELECT ID into #tableTempCondition FROM SPLIT_To_VARCHAR (@str)
	set @row = (SELECT count(ID) FROM SPLIT_To_VARCHAR (@str))
	set @countrow = 0
	set @index = 0
	while @row > 0
	begin
	set @index = 0
	set @ID = (select top 1 ID from #tableTempCondition)
	set @tempID = replace(@ID,'@',',')

	set @index = charindex('aw.workdate',@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCondition = 'and ('+@tempID
		set @condition2 =@tempCondition
	END
 
 
 	set @index = charindex('hp.codeemp',@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCondition = 'and ('+@tempID
		set @ProfileID =@tempCondition
	END

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1
	end

	drop table #tableTempCondition
	
DECLARE @Date_start DATETIME
DECLARE @Date_end DATETIME



SET @Date_start = SUBSTRING(@condition2, patindex('%[0-9]%', @condition2), 10)
SEt @Date_start = DATEADD(DAY,- 1,@Date_start)
SET @condition2 = REPLACE(@condition2,@Date_start,'')
SET @Date_end = SUBSTRING(@condition2, patindex('%[0-9]%', @condition2), 10)
SEt @Date_end = DATEADD(DAY,1,@Date_end)


--SELECT @ProfileID, @condition

SET @condition2 = ' and TimeLog between '''+CONVERT(VARCHAR(20),@Date_start,111)+''' and '''+CONVERT(VARCHAR(20),@Date_end,111)+''' and profileid in ( SELECT ID FROM Hre_Profile hp Where Isdelete is null ' + @ProfileID+ ')'
--SELECT @condition2

--SELECT @condition2

SET @query = 'DECLARE @tblPermission TABLE (id uniqueidentifier primary key )
INSERT INTO @tblPermission EXEC Get_Data_Permission_New ''' + @Username + ''', ' + '''Hre_Profile''' + '

SELECT  * 
INTO	#Att_TAMScanLog 
FROM	Att_TAMScanLog
WHERE   IsDelete IS NULL '+@condition2+'

select
--'+@queryTop+'
 CodeEmp,ProfileName,DateHire,OrgStructureName,JobTitleName,WorkDate as ''Ngay''

,ShiftCode,MachineNoIn, MachineNoOut

,InTime1,OutTime1,ShiftCode2,InTime2,OutTime2,LeaveCode as "LoaiNghi",
  VN  as "Loai"
 -- ,LeaveCode2,LeaveDurationType2
  ,Typeworkday as "LoaiNgay"
 -- ,TypeCode
  ,LateDuration1,EarlyDuration1,LateEarlyDuration
  ,GioDiLam1/NULLIF(GioCa1,0) + isnull(GioDiLam2,0)/NULLIF(GioCa2,0) as Cong,
  GioDiLam1/NULLIF(GioCa1,0)  as Cong1, isnull(GioDiLam2,0)/NULLIF(GioCa2,0) as Cong2
  ,GioThua1+GioThua2 as GioThua

  ,[E_WEEKEND] as OT200,[E_HOLIDAY] as OT300,[E_HOLIDAY_NIGHTSHIFT] as OT390,
  [E_WORKDAY_NIGHTSHIFT] as OT215,[E_WORKDAY] as OT150,[E_WEEKEND_NIGHTSHIFT] as OT270,[OT100] as OT210

  , Lan1, Lan2, Lan3, Lan4,GioCa1,GioCa2
  ,CongLamThem
  ,CongKhac,QuenCC
  ,Ca,TienPhatMuon,TienPhatThieuInOut, 
   isnull(TrucNgayLe,0) + (case when isnull(TrucNgayLe,0) > 0 then 0 else isnull(TrucCN,0) end) + ActualHoursAllowance as TienTruc,ID, SL1,SL 
  --,LateEarlyDuration
    ,ROW_NUMBER() OVER ( ORDER BY CodeEmp asc) as RowNumber
	, NULL AS "aw.workdate", NULL AS "hp.codeemp"  ,NULL as "cos.OrderNumber"
	
into #Results 
  FROM

   ( select distinct hp.id,aw.WorkDate,hp.CodeEmp,hp.ProfileName,cos.OrgStructureName,al.Code as LeaveCode,aw.InTime1,aw.OutTime1,cet.VN as Typeworkday,aw.LateDuration1,aw.EarlyDuration1,aw.LateEarlyDuration,
  CodeStatistic,ao.ConfirmHours,al.VN,cos.OrderNumber "cos.OrderNumber" ,hp.DateHire,cs.Code as ShiftCode,job.JobTitleName,al2.Code as LeaveCode2,al2.VN as LeaveDurationType2,
  (Case when ap.Type =''E_NEW_BORN_CHILD'' THEN ''x''
  ELSE NULL
  END
  ) TypeCode,aw.ID "awID"
  ,aw.InTime2,aw.OutTime2,cs2.Code as ShiftCode2

  --Ca1 Tong gio di lam
  ,
  (case when TinhCong.WorkHoursShift2<=0 then TinhCong.WorkPaidHours
  else TinhCong.WorkHoursShift1 
  end
  ) as GioDiLam1
  --Gio Thua
  , 
  (case when DATEDIFF(second, aw.InTime1, aw.OutTime1) / 3600.0 - (cs.cobreakout-cs.cobreakin) - cs.WorkHours-isnull(ao.ConfirmHours,0) +TinhCong.LeaveHours <0 then 0
  else  DATEDIFF(second, aw.InTime1, aw.OutTime1) / 3600.0 - (cs.cobreakout-cs.cobreakin) - cs.WorkHours-isnull(ao.ConfirmHours,0) +TinhCong.LeaveHours
  END
  )
  as GioThua1
  
  


  --Ca2 Tong gio di lam

  ,TinhCong.WorkHoursShift2/NULLIF(cs2.StdWorkHours, 0) as GioDiLam2
  --Gio Thua
  , 
  (case when DATEDIFF(second, aw.InTime1, aw.OutTime1) / 3600.0 - (cs2.cobreakout-cs2.cobreakin) - cs2.WorkHours <0 then 0
  else  DATEDIFF(second, aw.InTime1, aw.OutTime1) / 3600.0 - (cs2.cobreakout-cs2.cobreakin) - cs2.WorkHours
  END
  )
  as GioThua2

  ,cs.WorkHours as GioCa1,cs2.WorkHours as GioCa2,cs.cobreakout-cs.cobreakin as NghiTrua1,cs2.cobreakout-cs2.cobreakin as NghiTrua2
  ,ao.ConfirmHours/NULLIF(cs.WorkHours, 0) as CongLamThem
  , (case when TinhCong.LeaveTypeID in (select id from Cat_LeaveDayType where Code in(''H'',''CT'',''SL'')) then TinhCong.LeaveDays else 0 end) as CongKhac
  
 ,ct.TAMScanReasonMissName as QuenCC

   , (case 
  when  cs.Code is null then ''''
  when al.code is not null and al.code <>''MS'' and al.DurationType=''E_FULLSHIFT'' then al.Code
  when al.code is not null and al.code <>''MS'' and al.DurationType in(''E_FIRSTHALFSHIFT'') then CONCAT(al.Code,''/'',2,''-Truoc'')
  when al.code is not null and al.code <>''MS'' and al.DurationType in(''E_LASTHALFSHIFT'') then CONCAT(al.Code,''/'',2,''-Sau'')
  
  when ao.RegisterHours is not null and  al.Code is null  then CONCAT(REPLACE(cs.Code, ''KS_'', ''''),''/'',''LamThem-'',ao.RegisterHours/NULLIF(cs.StdWorkHours, 0),''/'',cs2.Code)

  when al.Code is not null and ao.RegisterHours is null    then CONCAT(REPLACE(cs.Code, ''KS_'', ''''),''/'',al.Code,''-'',FORMAT(al.DateStart,''hh:mm''),''-'',FORMAT(al.DateEnd,''hh:mm''),''/'',cs2.Code)
  
  when al.Code is  null and ao.RegisterHours is null and cs2.Code is null    then REPLACE(cs.Code, ''KS_'', '''')

  when al.Code is  null and ao.RegisterHours is null  and cs2.Code is not null   then CONCAT(REPLACE(cs.Code, ''KS_'', ''''),''/'',cs2.Code)

  ELSE CONCAT(REPLACE(cs.Code, ''KS_'', ''''),''/'',al.Code,''-'',al.LeaveHours,''/'',''LamThem-'',ao.RegisterHours/NULLIF(cs.StdWorkHours, 0),''/'',cs2.Code)
  END
  ) Ca

  , 
  ( case

   when TinhCong.LateEarlyCount >=1  then 50000

   else 0
   end
  ) as TienPhatMuon
  
  ,(case when aw.MissInOutReasonID1 not in (select id from Cat_TAMScanReasonMiss where Code in(''QCC01'',''QCC02'',''QCC04'',''QCC05'',''QCC06'',''QCC07'')) then 50000
  else 0
  end) 
   + (case when aw.MissInOutReasonID2 not in (select id from Cat_TAMScanReasonMiss where Code in(''QCC01'',''QCC02'',''QCC04'',''QCC05'',''QCC06'',''QCC07'')) then 50000
  else 0
  end) as TienPhatThieuInOut

  ,( case when aw.Workdate<= hp.DateEndProbation then TinhCong.ActualHoursAllowance*0.7
  else TinhCong.ActualHoursAllowance end
    ) as ActualHoursAllowance

  ,TienTrucNgayNghi.TrucNgayLe,TienTrucNgayNghi.TrucCN, SL1,SL
  --,aw.LateEarlyDuration 
  FROM Att_Workday aw 

  --Canteen
  left join (select cms.ProfileID,DATEADD(day,DATEDIFF(day, 0, TimeLog), 0) as Ngay ,count (cms.id) SL1
from Can_MealRecord cms
left join Can_MealBillEmployee cm on cm.ProfileID=cms.ProfileID and cm.DateMeal=DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) and cm.MealUnitID is null and cm.isdelete is null and (cm.Status is null or cm.Status<>''E_CANCEL'')
where cms.IsDelete is null
and cm.id is null
and cms.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB''))
group by cms.ProfileID,DATEADD(DAY , DATEDIFF(DAY , 0, TimeLog), 0)) KoDK_CoAn on KoDK_CoAn.profileid =aw.profileid and KoDK_CoAn.Ngay=aw.workdate 

  left join (select cm.ProfileID, cm.DateMeal,count(cm.ProfileID) SL 
from Can_MealBillEmployee cm
left join (select ProfileID,DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) as Ngay ,TimeLog,MachineCode
			from Can_MealRecord 
			where IsDelete is null) QuetThe on QuetThe.ProfileID=cm.ProfileID and QuetThe.Ngay=cm.DateMeal
where cm.IsDelete is null and QuetThe.TimeLog is null  and cm.MealUnitID is null
and (cm.Status is null or cm.Status<>''E_CANCEL'')
and cm.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB''))
group by cm.ProfileID, cm.DateMeal) CoDK_KhongAn on CoDK_KhongAn.profileid =aw.profileid and CoDK_KhongAn.DateMeal=aw.workdate 

  left join Cat_EnumTranslate ce on ce.EnumKey=aw.SrcType and ce.EnumName=''WorkdaySrcType''and ce.IsDelete is null
  left join Cat_EnumTranslate ce2 on ce2.EnumKey=aw.Type and ce2.EnumName=''WorkdayType'' and ce2.IsDelete is null

  left join (select aati.MissInOutReasonID,aati.LateEarlyCount,aati.LateEarlyMinutes,aat.ProfileID,aati.WorkDate,aati.WorkPaidHours,aati.WorkPaidHoursShift1,aati.WorkPaidHoursShift2,aati.WorkHoursShift1,aati.WorkHoursShift2
  ,LeaveDay1Days,LeaveDay1Type,aati.LeaveTypeID,aati.LeaveDays,aati.LeaveHours,aati.ActualHoursAllowance
  from Att_AttendanceTableItem aati
left join Att_AttendanceTable aat on aati.AttendanceTableID=aat.ID and aat.IsDelete is null
where aat.ProfileID is not null

) TinhCong on TinhCong.ProfileID=aw.ProfileID and TinhCong.WorkDate=aw.WorkDate

--left join (select ProfileID,Workdate, sum(LeaveHours) as LeaveHours from (
--select ProfileID,DATEADD(HOUR,0,convert(DATETIME,convert(DATE,DateStart))) as Workdate,LeaveHours from Att_LeaveDay where IsDelete is null

--and IsDelete is null and  Status<>''E_REJECTED''
--) abc group by ProfileID,Workdate)) NgayNghi on aw.ProfileID=NgayNghi.ProfileID and aw.WorkDate=NgayNghi.WorkDate
'
SET @query2=
'
----Tien Truc CN va NgayLe
left join (
select a.ID,a.WorkDate,
( case when  datepart(WEEKDAY,WorkDate) =1 and datediff(HOUR,a.FirstInTime,a.LastOutTime)>=c.StdWorkHours AND WorkDate<=hp.DateENDProbation AND hp.DateENDProbation is not null then 70000
when datepart(WEEKDAY,WorkDate) =1 and DateOff is   null and 100000*(datediff(MINUTE,a.FirstInTime,a.LastOutTime)/60)/NULLIF(c.StdWorkHours, 0) >100000  then 100000
when datepart(WEEKDAY,WorkDate) =1 and DateOff is   null  then 100000*(datediff(MINUTE,a.FirstInTime,a.LastOutTime)/60)/NULLIF(c.StdWorkHours, 0) 

else 0 end) as TrucCN,
(case when DateOff  is not null and WorkDate<hp.DateENDProbation and datediff(HOUR,a.FirstInTime,a.LastOutTime)>=c.StdWorkHours then 70000
when DateOff  is not null and WorkDate>=hp.DateENDProbation and datediff(HOUR,a.FirstInTime,a.LastOutTime)>=c.StdWorkHours then 100000
 when DateOff is not null and WorkDate>=hp.DateENDProbation and datediff(HOUR,a.FirstInTime,a.LastOutTime)<c.StdWorkHours and 100000*datediff(HOUR,a.FirstInTime,a.LastOutTime)/NULLIF(c.StdWorkHours, 0)>100000  then 100000
 when DateOff is not null and WorkDate>=hp.DateENDProbation and datediff(HOUR,a.FirstInTime,a.LastOutTime)<c.StdWorkHours then 100000*datediff(HOUR,a.FirstInTime,a.LastOutTime)/NULLIF(c.StdWorkHours, 0)
 
 
 else 0 end) as TrucNgayLe

 from Att_Workday a

left join hre_profile hp on a.Profileid = hp.id
left join Cat_DayOff b on a.WorkDate=b.DateOff and b.IsDelete is null
left join Cat_Shift c on c.id=a.ShiftID 
where  a.IsDelete is null and (c.StandardHoursAllowanceFomula is null or c.StandardHoursAllowanceFomula=''0'') 
and a.profileid not in ( select ProfileID from Att_Grade where isdelete is null and MonthStart = (select max(b.MonthStart) from Att_Grade b where a.ProfileID=b.ProfileID)  and GradeAttendanceID in (select id from Cat_GradeAttendance where Code in (''KCC_BV'',''BV_TV'',''BV03'',''BV17'',''BV18'',''BV04'',''BV06'',''BV12'',''BV09'',''BV10'',''PTM01'',''BV14'',''BV21'',''BV22'',''BV23'')) )
) TienTrucNgayNghi on TienTrucNgayNghi.id=aw.id
   left join Cat_TAMScanReasonMiss ct on ct.id=aw.MissInOutReason 
  left join Hre_Profile hp on aw.ProfileID = hp.ID and hp.IsDelete is NULL
  inner join @tblPermission tps on tps.ID = hp.id
  left join Cat_JobTitle job on job.ID = hp.JobTitleID and job.IsDelete is NULL
  left join Cat_OrgStructure cos on aw.OrgStructureID = cos.ID and cos.IsDelete is NULL
  left join Cat_OrgUnit cou on cou.ID = aw.OrgStructureID and cou.IsDelete is NULL
  left join Att_Pregnancy ap on ap.ProfileID = hp.ID and ap.IsDelete is NULL
 LEFT JOIN dbo.Cat_EnumTranslate AS cet ON cet.EnumKey = aw.Type AND cet.EnumName = ''WorkdayType''  and cet.isdelete is null
  
  left  join (select al.LeaveHours,al.DateStart,al.DateEnd,al.id,cl.Code,al.DurationType,VN from Att_LeaveDay al 
  left join Cat_LeaveDayType cl on cl.ID = al.LeaveDayTypeID and cl.isdelete is null
  left join Cat_EnumTranslate c on c.EnumKey = al.DurationType and c.IsDelete is NULL and EnumName=''LeaveDayDurationType'' where al.IsDelete is NULL and al.Status not in ( ''E_REJECTED'',''E_CANCEL'')) al on aw.LeaveDayID1 = al.ID
  
  left  join (select al.id,cl.Code,al.DurationType,VN from Att_LeaveDay al 
  left join Cat_LeaveDayType cl on cl.ID = al.LeaveDayTypeID and cl.isdelete is null
  left join Cat_EnumTranslate c on c.EnumKey = al.DurationType and cl.IsDelete is NULL and EnumName=''LeaveDayDurationType'' where al.IsDelete is NULL and al.Status not in( ''E_REJECTED'',''E_CANCEL'')) al2 on aw.ExtraLeaveDayID = al2.ID
  
  LEFT outer join (select a.RegisterHours,a.ConfirmHours,b.CodeStatistic,a.ProfileID,a.workdateroot FROM Att_Overtime a left join Cat_OvertimeType b on a.OvertimeTypeID = b.ID
    where a.Status not in ( ''E_REJECTED'',''E_CANCEL'') and a.IsDelete is NULL) ao on ao.profileid = aw.profileid and ao.workdateroot = aw.workdate
 
  left outer join cat_shift cs on cs.id = aw.shiftid
  left outer join cat_shift cs2 on cs2.id = aw.Shift2ID
   

  where aw.IsDelete is NULL and hp.codeemp is not null' + @condition + '
  
  ) as temp pivot (sum(temp.ConfirmHours) for temp.CodeStatistic in ([E_WEEKEND],[E_HOLIDAY],[E_HOLIDAY_NIGHTSHIFT],[E_WORKDAY_NIGHTSHIFT],[E_WORKDAY],[E_WEEKEND_NIGHTSHIFT],[OT100])) pvtbl

  left join 
  (
  select [1] as Lan1,[2] as Lan2,[3] as Lan3,[4] as Lan4,[5] as Lan5,[6] as Lan6,[7] as Lan7,
  [8] as Lan8,[9] as Lan9,[10] as Lan10 ,WorkdayID,MachineNoIn, MachineNoOut
FROM (
select distinct c1.TimeLog,ROW_NUMBER() over (PARTITION BY hp.CodeEmp,aw.WorkDate order by aw.WorkDate,c1.TimeLog) stt,aw.InTime1,aw.OutTime1,aw.ID WorkdayID
	, c1.MachineNo MachineNoIn, c2.MachineNo  MachineNoOut
  from Att_Workday aw
  left join Hre_Profile hp on aw.ProfileID = hp.ID and aw.IsDelete is NULL
  inner join @tblPermission tps on tps.ID = hp.id
  left join #Att_TAMScanLog c1 on aw.ProfileID = c1.ProfileID 
  and DAY(aw.InTime1) = DAY(c1.TimeLog) and MONTH(aw.InTime1) = MONTH(c1.TimeLog) and YEAR(aw.InTime1) = YEAR(c1.TimeLog)
  and DATEPART(HOUR, aw.InTime1) = DATEPART(HOUR, c1.TimeLog) and DATEPART(MINUTE, aw.InTime1) = DATEPART(MINUTE, c1.TimeLog)
  and c1.IsDelete is NULL

  left join #Att_TAMScanLog c2 on aw.ProfileID = c2.ProfileID 
  and DAY(aw.OutTime1) = DAY(c2.TimeLog) and MONTH(aw.OutTime1) = MONTH(c2.TimeLog) and YEAR(aw.OutTime1) = YEAR(c2.TimeLog)
  and DATEPART(HOUR, aw.OutTime1) = DATEPART(HOUR, c2.TimeLog) and DATEPART(MINUTE, aw.OutTime1) = DATEPART(MINUTE, c2.TimeLog)
  and c2.IsDelete is NULL

  left join Cat_OrgStructure cos on cos.ID = aw.OrgStructureID and cos.IsDelete is NULL
  --left join Cat_OrgUnit cou on cou.ID = aw.OrgStructureID and cou.IsDelete is NULL
  left join Cat_OrgUnit couu on couu.OrgstructureID = aw.OrgStructureID and couu.IsDelete is NULL
  left outer join Cat_Shift e on e.ID = aw.ShiftID and e.IsDelete is NULL
  where 1=1 '+@condition+'
  ) temp PIVOT (max(temp.TimeLog) for stt in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])) pvtbl
  
  ) RawInOut on RawInOut.WorkdayID = pvtbl.awID
  order by pvtbl.CodeEmp,pvtbl.WorkDate
 '
 --rpt_ChamCongHangNgay2_BV

SET @queryPageSize = '  ALTER TABLE #Results ADD TotalRow int
declare @totalRow int
SELECT @totalRow = COUNT(*) FROM #Results
update #Results set TotalRow = @totalRow
SELECT * FROM #Results WHERE RowNumber BETWEEN(' + CAST(@PageIndex AS VARCHAR) + ' -1) * ' + CAST(@PageSize AS VARCHAR) + ' + 1 AND(((' + CAST(@PageIndex AS VARCHAR) + ' -1) * ' + CAST(@PageSize AS VARCHAR) + ' + 1) + ' + CAST(@PageSize AS VARCHAR) + ') - 1
DROP TABLE #Results, #Att_TAMScanLog

'

PRINT (@query)
PRINT (@query2)
PRINT (@queryPageSize)
EXEC (@query + @query2 + @queryPageSize)

--[rpt_ChamCongHangNgay2_BV]
END


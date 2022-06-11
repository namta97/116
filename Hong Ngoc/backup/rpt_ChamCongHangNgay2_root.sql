USE [HONGNGOC]
GO
/****** Object:  StoredProcedure [dbo].[rpt_ChamCongHangNgay2]    Script Date: 5/19/2022 11:44:18 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [dbo].[rpt_ChamCongHangNgay2]
@condition varchar(max) = " AND (AW.WORKDATE = '2021/08/01' and hp.codeemp='01420')  ",
@PageIndex int = 1,
@PageSize int = 20,
@Username varchar(100) = 'dat.nguyen'
as
begin
declare @query varchar(max)
declare @querycondition varchar(max)
declare @queryPageSize varchar(max)
declare @queryTop varchar(10) = '  '
if(@PageSize = 0)
begin
SET @queryTop = ' Top 0 '
end


SET @query = 'DECLARE @tblPermission TABLE (id uniqueidentifier primary key )
INSERT INTO @tblPermission EXEC Get_Data_Permission_New ''' + @Username + ''', ' + '''Hre_Profile''' + '

select distinct CodeEmp,ProfileName,DateHire,OrgStructureName,JobTitleName,WorkDate as "WorkDate"

,ShiftCode

,InTime1,OutTime1,ShiftCode2,InTime2,OutTime2,LeaveCode as "LoaiNghi",
  VN  as "Loai"
 -- ,LeaveCode2,LeaveDurationType2
  ,Typeworkday as "LoaiNgay"
 -- ,TypeCode
  ,LateDuration1,EarlyDuration1,LateEarlyDuration
  ,GioDiLam1,GioThua1,GioDiLam2,GioThua2
  ,null as "co.OrderNumber",[E_WEEKEND] as OT200,[E_HOLIDAY] as OT300,[E_HOLIDAY_NIGHTSHIFT] as OT390,
  [E_WORKDAY_NIGHTSHIFT] as OT215,[E_WORKDAY] as OT150,[E_WEEKEND_NIGHTSHIFT] as OT270,[OT100] as OT210

  , Lan1, Lan2, Lan3, Lan4,GioCa1,GioCa2
  ,CongLamThem
  ,CongKhac,QuenCC
  ,Ca,TienPhatMuon,TienPhatThieuInOut,ActualHoursAllowance as TienTruc,ID,Note as ''Note'',AmountOfFine,GhiChuPhat,RewardValue,Reason, SL1,SL 
  --,LateEarlyDuration
    ,ROW_NUMBER() OVER ( ORDER BY CodeEmp asc) as RowNumber into #Results 
  FROM

   ( select distinct hp.id,aw.WorkDate,hp.CodeEmp,hp.ProfileName,co.OrgStructureName,al.Code as LeaveCode,aw.InTime1,aw.OutTime1,cet.VN as Typeworkday,aw.LateDuration1,aw.EarlyDuration1,aw.LateEarlyDuration,
  CodeStatistic,ao.ConfirmHours,al.VN,co.OrderNumber,hp.DateHire,cs.Code as ShiftCode,job.JobTitleName,al2.Code as LeaveCode2,al2.VN as LeaveDurationType2,
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

  ,TinhCong.WorkHoursShift2 as GioDiLam2
  --Gio Thua
  , 
  (case when DATEDIFF(second, aw.InTime1, aw.OutTime1) / 3600.0 - (cs2.cobreakout-cs2.cobreakin) - cs2.WorkHours <0 then 0
  else  DATEDIFF(second, aw.InTime1, aw.OutTime1) / 3600.0 - (cs2.cobreakout-cs2.cobreakin) - cs2.WorkHours
  END
  )
  as GioThua2

  ,cs.StdWorkHours as GioCa1,cs2.StdWorkHours as GioCa2,cs.cobreakout-cs.cobreakin as NghiTrua1,cs2.cobreakout-cs2.cobreakin as NghiTrua2
  ,ao.ConfirmHours/cs.WorkHours as CongLamThem
  , (case when TinhCong.LeaveTypeID in (select id from Cat_LeaveDayType where Code in(''H'',''DB'',''CT'',''SL'',''CH'')) then TinhCong.LeaveDays else 0 end) as CongKhac
  
 ,ct.TAMScanReasonMissName as QuenCC

   , (case 
  when  cs.Code is null then ''''
  when al.code is not null and al.code <>''MS'' and al.DurationType=''E_FULLSHIFT'' then al.Code
  when al.code is not null and al.code <>''MS'' and al.DurationType in(''E_FIRSTHALFSHIFT'') then CONCAT(al.Code,''/'',2,''-Truoc'')
  when al.code is not null and al.code <>''MS'' and al.DurationType in(''E_LASTHALFSHIFT'') then CONCAT(al.Code,''/'',2,''-Sau'')
  
  when ao.RegisterHours is not null and  al.Code is null  then CONCAT(REPLACE(cs.Code, ''KS_'', ''''),''/'',''OT-'',ao.RegisterHours,''/'',cs2.Code)

  when al.Code is not null and ao.RegisterHours is null    then CONCAT(REPLACE(cs.Code, ''KS_'', ''''),''/'',al.Code,''-'',FORMAT(al.DateStart,''hh:mm''),''-'',FORMAT(al.DateEnd,''hh:mm''),''/'',cs2.Code)
  
  when al.Code is  null and ao.RegisterHours is null and cs2.Code is null    then REPLACE(cs.Code, ''KS_'', '''')

  when al.Code is  null and ao.RegisterHours is null  and cs2.Code is not null   then CONCAT(REPLACE(cs.Code, ''KS_'', ''''),''/'',cs2.Code)

  ELSE CONCAT(REPLACE(cs.Code, ''KS_'', ''''),''/'',al.Code,''-'',al.LeaveHours,''/'',''OT-'',ao.RegisterHours,''/'',cs2.Code)
  END
  ) Ca

  , 
  ( case
   when TinhCong.LateEarlyMinutes <=3 then 0
   when TinhCong.LateEarlyMinutes >3 and TinhCong.LateEarlyMinutes <10  then 30000
   when TinhCong.LateEarlyMinutes >=10 and TinhCong.LateEarlyMinutes <30 then 50000
   when TinhCong.LateEarlyMinutes >=30  then 100000
   else 0
   end
  ) as TienPhatMuon
  
  ,(case when TinhCong.MissInOutReasonID not in (select id from Cat_TAMScanReasonMiss where Code in(''QCC01'',''QCC04'',''QCC05'',''QCC07'')) then 30000
  else 0
  end) as TienPhatThieuInOut
  ,TinhCong.ActualHoursAllowance,TinhCong.LeaveDayTypeName 
  , concat(al.Comment,al2.Comment,hd.Notes) as Note , hd.AmountOfFine,hd.Notes as GhiChuPhat,RewardValue ,Reason, SL1,SL
  --,aw.LateEarlyDuration 
  FROM Att_Workday aw 

  --Canteen
  left join (select cms.ProfileID,DATEADD(day,DATEDIFF(day, 0, TimeLog), 0) as Ngay ,count (cms.id) SL1
from Can_MealRecord cms
left join Can_MealBillEmployee cm on cm.ProfileID=cms.ProfileID and cm.DateMeal=DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) and cm.MealUnitID is null and cm.isdelete is null and (cm.Status is null or cm.Status<>''E_CANCEL'')
where cms.IsDelete is null
and cm.id is null
and cms.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB'',''SANGLOCHM''))
group by cms.ProfileID,DATEADD(DAY , DATEDIFF(DAY , 0, TimeLog), 0)) KoDK_CoAn on KoDK_CoAn.profileid =aw.profileid and KoDK_CoAn.Ngay=aw.workdate 

  left join (select cm.ProfileID, cm.DateMeal,count(cm.ProfileID) SL 
from Can_MealBillEmployee cm
left join (select ProfileID,DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) as Ngay ,TimeLog,MachineCode
			from Can_MealRecord 
			where IsDelete is null) QuetThe on QuetThe.ProfileID=cm.ProfileID and QuetThe.Ngay=cm.DateMeal
where cm.IsDelete is null and QuetThe.TimeLog is null  and cm.MealUnitID is null
and (cm.Status is null or cm.Status<>''E_CANCEL'')
and cm.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB'',''SANGLOCHM''))
group by cm.ProfileID, cm.DateMeal) CoDK_KhongAn on CoDK_KhongAn.profileid =aw.profileid and CoDK_KhongAn.DateMeal=aw.workdate 


  left join Hre_Discipline hd on hd.profileid=aw.profileid and hd.DateOfEffective=aw.WorkDate and hd.isdelete is null
   left join Hre_Reward hr on hr.profileid=aw.profileid and hr.DateOfEffective=aw.WorkDate and hr.isdelete is null

  left join Cat_TAMScanReasonMiss ct on ct.id=aw.MissInOutReason 
  left join Cat_EnumTranslate ce on ce.EnumKey=aw.SrcType and ce.EnumName=''WorkdaySrcType'' and ce.isdelete is null
  left join Cat_EnumTranslate ce2 on ce2.EnumKey=aw.Type and ce2.EnumName=''WorkdayType'' and ce2.isdelete is null

  left join (select aati.MissInOutReasonID,aati.LateEarlyCount,aati.LateEarlyMinutes,aat.ProfileID,aati.WorkDate,aati.WorkPaidHours,aati.WorkPaidHoursShift1,aati.WorkPaidHoursShift2,aati.WorkHoursShift1,aati.WorkHoursShift2
  ,LeaveDay1Days,LeaveDay1Type,aati.LeaveTypeID,aati.LeaveDays,aati.LeaveHours,aati.ActualHoursAllowance,cl.LeaveDayTypeName
  from Att_AttendanceTableItem aati
left join Att_AttendanceTable aat on aati.AttendanceTableID=aat.ID and aat.IsDelete is null
left join Cat_LeaveDayType cl on cl.id=aati.LeaveTypeID and cl.PaidRate=1
where aat.ProfileID is not null ) TinhCong on TinhCong.ProfileID=aw.ProfileID and TinhCong.WorkDate=aw.WorkDate

--left join (select ProfileID,Workdate, sum(LeaveHours) as LeaveHours from (
--select ProfileID,DATEADD(HOUR,0,convert(DATETIME,convert(DATE,DateStart))) as Workdate,LeaveHours from Att_LeaveDay where IsDelete is null

--and IsDelete is null and  Status<>''E_REJECTED''
--) abc group by ProfileID,Workdate)) NgayNghi on aw.ProfileID=NgayNghi.ProfileID and aw.WorkDate=NgayNghi.WorkDate

----Tien Truc CN va NgayLe
left join (
select a.ID,a.WorkDate,
( case when datepart(WEEKDAY,WorkDate) =1 and datediff(HOUR,a.FirstInTime,a.LastOutTime)>=c.StdWorkHours then 100000
when DateOff is not null and datediff(HOUR,a.FirstInTime,a.LastOutTime)<c.StdWorkHours then 100000*datediff(HOUR,a.FirstInTime,a.LastOutTime)/c.StdWorkHours
else 0 end) as TrucCN,
(case when DateOff is not null and datediff(HOUR,a.FirstInTime,a.LastOutTime)>=c.StdWorkHours then 200000
 when DateOff is not null and datediff(HOUR,a.FirstInTime,a.LastOutTime)<c.StdWorkHours then 200000*datediff(HOUR,a.FirstInTime,a.LastOutTime)/c.StdWorkHours
 else 0 end) as TrucNgayLe

 from Att_Workday a
left join Cat_DayOff b on a.WorkDate=b.DateOff and b.IsDelete is null
left join Cat_Shift c on c.id=a.ShiftID
where a.IsDelete is null) TienTrucNgayNghi on TienTrucNgayNghi.id=aw.id



  left join Hre_Profile hp on aw.ProfileID = hp.ID and hp.IsDelete is NULL
  inner join @tblPermission tps on tps.ID = hp.id
  left join Cat_JobTitle job on job.ID = hp.JobTitleID and job.IsDelete is NULL
  left join Cat_OrgStructure co on hp.OrgStructureID = co.ID and co.IsDelete is NULL
  left join Cat_OrgUnit cou on cou.ID = hp.OrgStructureID and cou.IsDelete is NULL
  left join Att_Pregnancy ap on ap.ProfileID = hp.ID and ap.IsDelete is NULL

 LEFT JOIN dbo.Cat_EnumTranslate AS cet ON cet.EnumKey = aw.Type AND cet.EnumName = ''WorkdayType''  and cet.isdelete is null
  
  left OUTER join (select al.LeaveHours,al.DateStart,al.DateEnd,al.id,cl.Code,al.DurationType,VN,al.Comment from Att_LeaveDay al 
  left join Cat_LeaveDayType cl on cl.ID = al.LeaveDayTypeID and cl.isdelete is null
 left join Cat_EnumTranslate c on c.EnumKey = al.DurationType and c.IsDelete is NULL and EnumName=''LeaveDayDurationType'' where al.IsDelete is NULL and al.Status not in ( ''E_REJECTED'',''E_CANCEL'')) al on aw.LeaveDayID1 = al.ID
  
  left OUTER join (select al.id,cl.Code,al.DurationType,VN,al.Comment from Att_LeaveDay al 
  left join Cat_LeaveDayType cl on cl.ID = al.LeaveDayTypeID and cl.isdelete is null
  left join Cat_EnumTranslate c on c.EnumKey = al.DurationType and c.isdelete is null and EnumName=''LeaveDayDurationType'' and cl.IsDelete is NULL and al.IsDelete is NULL and al.Status not in( ''E_REJECTED'',''E_CANCEL'')) al2 on aw.ExtraLeaveDayID = al2.ID
  
  LEFT outer join (select sum(a.RegisterHours) as RegisterHours,sum(a.ConfirmHours) as ConfirmHours,b.CodeStatistic,a.ProfileID,a.workdateroot FROM Att_Overtime a left join Cat_OvertimeType b on a.OvertimeTypeID = b.ID
    where a.Status not in ( ''E_REJECTED'',''E_CANCEL'') and a.IsDelete is NULL
	and a.MethodPayment=''E_CASHOUT''
		group by b.CodeStatistic,a.ProfileID,a.workdateroot 
	) ao on ao.profileid = aw.profileid and ao.workdateroot = aw.workdate
 
  left outer join cat_shift cs on cs.id = aw.shiftid
  left outer join cat_shift cs2 on cs2.id = aw.Shift2ID
   

  where aw.IsDelete is NULL and hp.codeemp is not null' + @condition + '
  
  ) as temp pivot (sum(temp.ConfirmHours) for temp.CodeStatistic in ([E_WEEKEND],[E_HOLIDAY],[E_HOLIDAY_NIGHTSHIFT],[E_WORKDAY_NIGHTSHIFT],[E_WORKDAY],[E_WEEKEND_NIGHTSHIFT],[OT100])) pvtbl

  left join 
  (
  select [1] as Lan1,[2] as Lan2,[3] as Lan3,[4] as Lan4,[5] as Lan5,[6] as Lan6,[7] as Lan7,
  [8] as Lan8,[9] as Lan9,[10] as Lan10 ,WorkdayID
FROM (
select distinct c.TimeLog,ROW_NUMBER() over (PARTITION BY b.CodeEmp,a.WorkDate order by a.WorkDate,c.TimeLog) stt,a.InTime1,a.OutTime1,a.ID WorkdayID
  from Att_Workday a 
  left join Hre_Profile b on a.ProfileID = b.ID and a.IsDelete is NULL
  inner join @tblPermission tps on tps.ID = b.id
  left join Att_TAMScanLog c on a.ProfileID = c.ProfileID and DAY(a.WorkDate) = DAY(c.TimeLog) and MONTH(a.WorkDate) = MONTH(c.TimeLog) and YEAR(a.WorkDate) = YEAR(c.TimeLog)
  and c.IsDelete is NULL
  left join Cat_OrgStructure d on d.ID = a.OrgStructureID and d.IsDelete is NULL
  --left join Cat_OrgUnit cou on cou.ID = a.OrgStructureID and cou.IsDelete is NULL
  left join Cat_OrgUnit couu on couu.OrgstructureID = a.OrgStructureID and couu.IsDelete is NULL
  left outer join Cat_Shift e on e.ID = a.ShiftID and e.IsDelete is NULL
  where 1=1
  ) temp PIVOT (max(temp.TimeLog) for stt in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])) pvtbl
  
  ) RawInOut on RawInOut.WorkdayID = pvtbl.awID
  order by pvtbl.CodeEmp,pvtbl.WorkDate
 '

SET @queryPageSize = '  ALTER TABLE #Results ADD TotalRow int
declare @totalRow int
SELECT @totalRow = COUNT(*) FROM #Results
update #Results set TotalRow = @totalRow
SELECT * FROM #Results WHERE RowNumber BETWEEN(' + CAST(@PageIndex AS VARCHAR) + ' -1) * ' + CAST(@PageSize AS VARCHAR) + ' + 1 AND(((' + CAST(@PageIndex AS VARCHAR) + ' -1) * ' + CAST(@PageSize AS VARCHAR) + ' + 1) + ' + CAST(@PageSize AS VARCHAR) + ') - 1
DROP TABLE #Results
'
EXEC (@query + @queryPageSize)
PRINT (@query)
PRINT (@queryPageSize)

PRINT (@queryPageSize)
END

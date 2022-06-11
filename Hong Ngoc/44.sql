BEGIN tran
DECLARE @tblPermission TABLE (id uniqueidentifier primary key )
INSERT INTO @tblPermission EXEC Get_Data_Permission_New 'support', 'Hre_Profile'

SELECT  * 
INTO	#Att_TAMScanLog 
FROM	Att_TAMScanLog
WHERE   IsDelete IS NULL  and TimeLog between '2022/02/28' and '2022/04/02' and profileid in ( SELECT ID FROM Hre_Profile hp Where Isdelete is null  )


--SELECT ProfileID,COUNT(*) FROM #Att_TAMScanLog GROUP BY ProfileID
--ROLLBACK RETURN
select
--
 CodeEmp,ProfileName,DateHire,OrgStructureName,JobTitleName,WorkDate as 'Ngay'

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
  ,'' as "co.OrderNumber"
  ,[E_WEEKEND] as OT200,[E_HOLIDAY] as OT300,[E_HOLIDAY_NIGHTSHIFT] as OT390,
  [E_WORKDAY_NIGHTSHIFT] as OT215,[E_WORKDAY] as OT150,[E_WEEKEND_NIGHTSHIFT] as OT270,[OT100] as OT210

  , Lan1, Lan2, Lan3, Lan4,GioCa1,GioCa2
  ,CongLamThem
  ,CongKhac,QuenCC
  ,Ca,TienPhatMuon,TienPhatThieuInOut, 
   isnull(TrucNgayLe,0) + (case when isnull(TrucNgayLe,0) > 0 then 0 else isnull(TrucCN,0) end) + ActualHoursAllowance as TienTruc,ID, SL1,SL 
  --,LateEarlyDuration
    ,ROW_NUMBER() OVER ( ORDER BY CodeEmp asc) as RowNumber 
	
into #Results 
  FROM

   ( select distinct hp.id,aw.WorkDate,hp.CodeEmp,hp.ProfileName,co.OrgStructureName,al.Code as LeaveCode,aw.InTime1,aw.OutTime1,cet.VN as Typeworkday,aw.LateDuration1,aw.EarlyDuration1,aw.LateEarlyDuration,
  CodeStatistic,ao.ConfirmHours,al.VN,co.OrderNumber "co.OrderNumber" ,hp.DateHire,cs.Code as ShiftCode,job.JobTitleName,al2.Code as LeaveCode2,al2.VN as LeaveDurationType2,
  (Case when ap.Type ='E_NEW_BORN_CHILD' THEN 'x'
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
  , (case when TinhCong.LeaveTypeID in (select id from Cat_LeaveDayType where Code in('H','CT','SL')) then TinhCong.LeaveDays else 0 end) as CongKhac
  
 ,ct.TAMScanReasonMissName as QuenCC

   , (case 
  when  cs.Code is null then ''
  when al.code is not null and al.code <>'MS' and al.DurationType='E_FULLSHIFT' then al.Code
  when al.code is not null and al.code <>'MS' and al.DurationType in('E_FIRSTHALFSHIFT') then CONCAT(al.Code,'/',2,'-Truoc')
  when al.code is not null and al.code <>'MS' and al.DurationType in('E_LASTHALFSHIFT') then CONCAT(al.Code,'/',2,'-Sau')
  
  when ao.RegisterHours is not null and  al.Code is null  then CONCAT(REPLACE(cs.Code, 'KS_', ''),'/','LamThem-',ao.RegisterHours/NULLIF(cs.StdWorkHours, 0),'/',cs2.Code)

  when al.Code is not null and ao.RegisterHours is null    then CONCAT(REPLACE(cs.Code, 'KS_', ''),'/',al.Code,'-',FORMAT(al.DateStart,'hh:mm'),'-',FORMAT(al.DateEnd,'hh:mm'),'/',cs2.Code)
  
  when al.Code is  null and ao.RegisterHours is null and cs2.Code is null    then REPLACE(cs.Code, 'KS_', '')

  when al.Code is  null and ao.RegisterHours is null  and cs2.Code is not null   then CONCAT(REPLACE(cs.Code, 'KS_', ''),'/',cs2.Code)

  ELSE CONCAT(REPLACE(cs.Code, 'KS_', ''),'/',al.Code,'-',al.LeaveHours,'/','LamThem-',ao.RegisterHours/NULLIF(cs.StdWorkHours, 0),'/',cs2.Code)
  END
  ) Ca

  , 
  ( case

   when TinhCong.LateEarlyCount >=1  then 50000

   else 0
   end
  ) as TienPhatMuon
  
  ,(case when aw.MissInOutReasonID1 not in (select id from Cat_TAMScanReasonMiss where Code in('QCC01','QCC02','QCC04','QCC05','QCC06','QCC07')) then 50000
  else 0
  end) 
   + (case when aw.MissInOutReasonID2 not in (select id from Cat_TAMScanReasonMiss where Code in('QCC01','QCC02','QCC04','QCC05','QCC06','QCC07')) then 50000
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
left join Can_MealBillEmployee cm on cm.ProfileID=cms.ProfileID and cm.DateMeal=DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) and cm.MealUnitID is null and cm.isdelete is null and (cm.Status is null or cm.Status<>'E_CANCEL')
where cms.IsDelete is null
and cm.id is null
and cms.CanteenID not in (select id from can_Canteen where CanteenCode  in ('SANGLOCPTM','SANGLOCYN','SANGLOCLB'))
group by cms.ProfileID,DATEADD(DAY , DATEDIFF(DAY , 0, TimeLog), 0)) KoDK_CoAn on KoDK_CoAn.profileid =aw.profileid and KoDK_CoAn.Ngay=aw.workdate 

 left join (select cm.ProfileID, cm.DateMeal,count(cm.ProfileID) SL 
			from Can_MealBillEmployee cm
			left join (select ProfileID,DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) as Ngay ,TimeLog,MachineCode
						from Can_MealRecord 
						where IsDelete is null) QuetThe on QuetThe.ProfileID=cm.ProfileID and QuetThe.Ngay=cm.DateMeal
			where cm.IsDelete is null and QuetThe.TimeLog is null  and cm.MealUnitID is null
			and (cm.Status is null or cm.Status<>'E_CANCEL')
			and cm.CanteenID not in (select id from can_Canteen where CanteenCode  in ('SANGLOCPTM','SANGLOCYN','SANGLOCLB'))
			group by cm.ProfileID, cm.DateMeal
		) CoDK_KhongAn on CoDK_KhongAn.profileid =aw.profileid and CoDK_KhongAn.DateMeal=aw.workdate 

  left join Cat_EnumTranslate ce on ce.EnumKey=aw.SrcType and ce.EnumName='WorkdaySrcType'and ce.IsDelete is null
  left join Cat_EnumTranslate ce2 on ce2.EnumKey=aw.Type and ce2.EnumName='WorkdayType' and ce2.IsDelete is null

  left join (select aati.MissInOutReasonID,aati.LateEarlyCount,aati.LateEarlyMinutes,aat.ProfileID,aati.WorkDate,aati.WorkPaidHours,aati.WorkPaidHoursShift1,aati.WorkPaidHoursShift2,aati.WorkHoursShift1,aati.WorkHoursShift2
  ,LeaveDay1Days,LeaveDay1Type,aati.LeaveTypeID,aati.LeaveDays,aati.LeaveHours,aati.ActualHoursAllowance
  from Att_AttendanceTableItem aati
left join Att_AttendanceTable aat on aati.AttendanceTableID=aat.ID and aat.IsDelete is null
where aat.ProfileID is not null

) TinhCong on TinhCong.ProfileID=aw.ProfileID and TinhCong.WorkDate=aw.WorkDate

--left join (select ProfileID,Workdate, sum(LeaveHours) as LeaveHours from (
--select ProfileID,DATEADD(HOUR,0,convert(DATETIME,convert(DATE,DateStart))) as Workdate,LeaveHours from Att_LeaveDay where IsDelete is null

--and IsDelete is null and  Status<>'E_REJECTED'
--) abc group by ProfileID,Workdate)) NgayNghi on aw.ProfileID=NgayNghi.ProfileID and aw.WorkDate=NgayNghi.WorkDate

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
where  a.IsDelete is null and (c.StandardHoursAllowanceFomula is null or c.StandardHoursAllowanceFomula='0') 
and a.profileid not in ( select ProfileID from Att_Grade where isdelete is null and MonthStart = (select max(b.MonthStart) from Att_Grade b where a.ProfileID=b.ProfileID)  and GradeAttendanceID in (select id from Cat_GradeAttendance where Code in ('KCC_BV','BV_TV','BV03','BV17','BV18','BV04','BV06','BV12','BV09','BV10','PTM01','BV14','BV21','BV22','BV23')) )
) TienTrucNgayNghi on TienTrucNgayNghi.id=aw.id
   left join Cat_TAMScanReasonMiss ct on ct.id=aw.MissInOutReason 
  left join Hre_Profile hp on aw.ProfileID = hp.ID and hp.IsDelete is NULL
  inner join @tblPermission tps on tps.ID = hp.id
  left join Cat_JobTitle job on job.ID = hp.JobTitleID and job.IsDelete is NULL
  left join Cat_OrgStructure co on aw.OrgStructureID = co.ID and co.IsDelete is NULL
  left join Cat_OrgUnit cou on cou.ID = aw.OrgStructureID and cou.IsDelete is NULL
  left join Att_Pregnancy ap on ap.ProfileID = hp.ID and ap.IsDelete is NULL
 LEFT JOIN dbo.Cat_EnumTranslate AS cet ON cet.EnumKey = aw.Type AND cet.EnumName = 'WorkdayType'  and cet.isdelete is null
  
  left  join (select al.LeaveHours,al.DateStart,al.DateEnd,al.id,cl.Code,al.DurationType,VN from Att_LeaveDay al 
  left join Cat_LeaveDayType cl on cl.ID = al.LeaveDayTypeID and cl.isdelete is null
  left join Cat_EnumTranslate c on c.EnumKey = al.DurationType and c.IsDelete is NULL and EnumName='LeaveDayDurationType' where al.IsDelete is NULL and al.Status not in ( 'E_REJECTED','E_CANCEL')) al on aw.LeaveDayID1 = al.ID
  
  left  join (select al.id,cl.Code,al.DurationType,VN from Att_LeaveDay al 
  left join Cat_LeaveDayType cl on cl.ID = al.LeaveDayTypeID and cl.isdelete is null
  left join Cat_EnumTranslate c on c.EnumKey = al.DurationType and cl.IsDelete is NULL and EnumName='LeaveDayDurationType' where al.IsDelete is NULL and al.Status not in( 'E_REJECTED','E_CANCEL')) al2 on aw.ExtraLeaveDayID = al2.ID
  
  LEFT outer join (select a.RegisterHours,a.ConfirmHours,b.CodeStatistic,a.ProfileID,a.workdateroot FROM Att_Overtime a left join Cat_OvertimeType b on a.OvertimeTypeID = b.ID
    where a.Status not in ( 'E_REJECTED','E_CANCEL') and a.IsDelete is NULL) ao on ao.profileid = aw.profileid and ao.workdateroot = aw.workdate
 
  left outer join cat_shift cs on cs.id = aw.shiftid
  left outer join cat_shift cs2 on cs2.id = aw.Shift2ID
   

  where aw.IsDelete is NULL and hp.codeemp is not null AND (aw.workdate between '2022-01-01' and '2022-01-31') 
  
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

  left join Cat_OrgStructure d on d.ID = aw.OrgStructureID and d.IsDelete is NULL
  --left join Cat_OrgUnit cou on cou.ID = aw.OrgStructureID and cou.IsDelete is NULL
  left join Cat_OrgUnit couu on couu.OrgstructureID = aw.OrgStructureID and couu.IsDelete is NULL
  left outer join Cat_Shift e on e.ID = aw.ShiftID and e.IsDelete is NULL
  where 1=1  AND (aw.workdate between '2022-01-01' and '2022-01-31') 
  ) temp PIVOT (max(temp.TimeLog) for stt in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])) pvtbl
  
  ) RawInOut on RawInOut.WorkdayID = pvtbl.awID
  order by pvtbl.CodeEmp,pvtbl.WorkDate
 
  ALTER TABLE #Results ADD TotalRow int
declare @totalRow int
SELECT @totalRow = COUNT(*) FROM #Results
update #Results set TotalRow = @totalRow
SELECT * FROM #Results WHERE RowNumber BETWEEN(1 -1) * 100 + 1 AND(((1 -1) * 100 + 1) + 100) - 1
DROP TABLE #Results

ROLLBACK
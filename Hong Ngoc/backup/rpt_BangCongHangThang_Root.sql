  
  
alter proc dbo.rpt_BangCongHangThang 
@condition VARCHAR(MAX) =" and CodeEmp in ('01291') and (MonthYear='2022-01-01')  ",  
@PageIndex INT = 1,  
@PageSize INT = 100,  
@Username varchar(100) = 'support'  
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
if @condition is null  
set @condition='and abc.CodeEmp in (01317) and (abc.MonthYear=''2021-09-01'')'  
--print @condition return  
SET @query = ' DECLARE @tblPermission TABLE (id uniqueidentifier primary key )  
INSERT INTO @tblPermission EXEC Get_Data_Permission_New ''' + @Username + ''', ' + '''Hre_Profile''' + '  
--MuonSom  
--thieu in out  
  
select  CodeEmp ,ProfileName, PositionName, OrgStructureName, MonthYear , OrderNumber "abc.OrderNumber"  
,[C16],[C17],[C18],[C19],[C20],[C21],[C22],[C23],[C24],[C25],[C26],[C27],[C28],[C29],[C30],[C31]  
  ,[C1],[C2],[C3],[C4],[C5],[C6],[C7],[C8],[C9],[C10],[C11],[C12],[C13],[C14],[C15], CongKhac,CutOffDurationID  
  ,StdWorkDayCount,OT,P_DAY,SL_MuonSom,SL_ThieuInOut,TienTruc,datequit,DateStart,DateEnd,BatDauTS,KetThucTS,TongCongThua  
  ,ThieuInOut,MuonSom,Tien_Muon,Days as PhepUng,CongThua,Note,TienPhatKhac,LyDoPhat,ViPhamThaiSan,RewardValue,Reason,SL1,SL2,DienGiai1,DienGiai2  
 ,ID , ROW_NUMBER() OVER ( ORDER BY CodeEmp asc) as RowNumber   
  into #Results   
 from (select *   
 from (  
SELECT hp.id,hp.CodeEmp,hp.ProfileName,cp.PositionName,co.OrgStructureName  
,hp.datequit,at.MonthYear,at.CutOffDurationID,co.OrderNumber,concat(''C'',DATEPART(day,ati.WorkDate)) as Ngay,at.StdWorkDayCount,OTT as OT,  
(case  
when cs1.Code=''KS_TVU1'' then ati.WorkPaidHours/8  
when ati.WorkHoursShift2 >0 then  ati.WorkHoursShift1/nullif(cs1.StdWorkHours,0)*1.0 +ati.WorkHoursShift2/nullif(cs2.StdWorkHours,0)*1.0  
else  ati.WorkPaidHours/nullif(cs1.StdWorkHours ,0)  
end  
) as Cong,  
( case  
when at.LeaveDay1Type in (select id from Cat_LeaveDayType where Code=''H'') then at.LeaveDay1Days  
when at.LeaveDay2Type in (select id from Cat_LeaveDayType where Code=''H'') then at.LeaveDay2Days  
when at.LeaveDay3Type in (select id from Cat_LeaveDayType where Code=''H'') then at.LeaveDay3Days  
when at.LeaveDay4Type in (select id from Cat_LeaveDayType where Code=''H'') then at.LeaveDay4Days  
when at.LeaveDay5Type in (select id from Cat_LeaveDayType where Code=''H'') then at.LeaveDay5Days  
when at.LeaveDay6Type in (select id from Cat_LeaveDayType where Code=''H'') then at.LeaveDay6Days  
else 0 end)   
+( case  
when at.LeaveDay2Type in (select id from Cat_LeaveDayType where Code=''CT'') then at.LeaveDay2Days  
when at.LeaveDay1Type in (select id from Cat_LeaveDayType where Code=''CT'') then at.LeaveDay1Days  
when at.LeaveDay3Type in (select id from Cat_LeaveDayType where Code=''CT'') then at.LeaveDay3Days  
when at.LeaveDay4Type in (select id from Cat_LeaveDayType where Code=''CT'') then at.LeaveDay4Days  
when at.LeaveDay5Type in (select id from Cat_LeaveDayType where Code=''CT'') then at.LeaveDay5Days  
when at.LeaveDay6Type in (select id from Cat_LeaveDayType where Code=''CT'') then at.LeaveDay6Days  
else 0 end)  
+( case  
when at.LeaveDay1Type in (select id from Cat_LeaveDayType where Code=''CH'') then at.LeaveDay1Days  
when at.LeaveDay2Type in (select id from Cat_LeaveDayType where Code=''CH'') then at.LeaveDay2Days  
when at.LeaveDay3Type in (select id from Cat_LeaveDayType where Code=''CH'') then at.LeaveDay3Days  
when at.LeaveDay4Type in (select id from Cat_LeaveDayType where Code=''CH'') then at.LeaveDay4Days  
when at.LeaveDay5Type in (select id from Cat_LeaveDayType where Code=''CH'') then at.LeaveDay5Days  
when at.LeaveDay6Type in (select id from Cat_LeaveDayType where Code=''CH'') then at.LeaveDay6Days  
else 0 end)   
+( case  
when at.LeaveDay2Type in (select id from Cat_LeaveDayType where Code=''DB'') then at.LeaveDay2Days  
when at.LeaveDay1Type in (select id from Cat_LeaveDayType where Code=''DB'') then at.LeaveDay1Days  
when at.LeaveDay3Type in (select id from Cat_LeaveDayType where Code=''DB'') then at.LeaveDay3Days  
when at.LeaveDay4Type in (select id from Cat_LeaveDayType where Code=''DB'') then at.LeaveDay4Days  
when at.LeaveDay5Type in (select id from Cat_LeaveDayType where Code=''DB'') then at.LeaveDay5Days  
when at.LeaveDay6Type in (select id from Cat_LeaveDayType where Code=''DB'') then at.LeaveDay6Days  
else 0 end)  
+( case  
when at.LeaveDay2Type in (select id from Cat_LeaveDayType where Code=''SL'') then at.LeaveDay2Days  
when at.LeaveDay1Type in (select id from Cat_LeaveDayType where Code=''SL'') then at.LeaveDay1Days  
when at.LeaveDay3Type in (select id from Cat_LeaveDayType where Code=''SL'') then at.LeaveDay3Days  
when at.LeaveDay4Type in (select id from Cat_LeaveDayType where Code=''SL'') then at.LeaveDay4Days  
when at.LeaveDay5Type in (select id from Cat_LeaveDayType where Code=''SL'') then at.LeaveDay5Days  
when at.LeaveDay6Type in (select id from Cat_LeaveDayType where Code=''SL'') then at.LeaveDay6Days  
else 0 end)  as CongKhac,  
( case  
when at.LeaveDay2Type in (select id from Cat_LeaveDayType where Code=''P'') then at.LeaveDay2Days  
when at.LeaveDay1Type in (select id from Cat_LeaveDayType where Code=''P'') then at.LeaveDay1Days  
else 0 end) as P_DAY  
, SoLanMuon as SL_MuonSom ,MissInOut.SL_ThieuInOut,at.ActualHoursAllowance as TienTruc  
,at.DateStart,at.DateEnd,al.DateStart as BatDauTS,al.DateEnd as KetThucTS  
,ThieuInOut,MuonSom,Tien_Muon, ale.Days  
, isnull(CC.ActualHours1*-1,0) + isnull(cc1.ActualHours,0) as CongThua  
,concat(CC.Note,  cc1.Note)as Note  
,PhatKhac.AmountOfFine as TienPhatKhac,ConCat(PhatKhac.Notes,VPTS.Notes) as LyDoPhat  
,VPTS.AmountOfFine as ViPhamThaiSan,VPTS.NameEntityName,hr1.RewardValue, hr1.Reason,ac.InitAvailable as TongCongThua  
,SL1,SL2,DienGiai1,DienGiai2  
from Att_AttendanceTable at  
left join Att_CompensationConfig ac on ac.profileid=at.profileid  and at.monthyear >=''2021-08-01''  
left join Hre_Reward hr1 on hr1.ProfileID=at.ProfileID and at.MonthYear=hr1.DateOfEffective and hr1.IsDelete is null  
 inner join @tblPermission tps on tps.ID = at.ProfileID  
  LEFT JOIN Att_AttendanceTableItem ati on at.ID=ati.AttendanceTableID and ati.IsDelete is NULL  
  LEFT join Hre_Profile hp on hp.ID=at.ProfileID and hp.isdelete is null  
  left join  Att_AnnualLeaveExtend ale on ale.profileid=at.profileid and at.DateStart>=ale.monthstart and at.dateend<=ale.monthend and ale.isdelete is null  
  
left join (select ProfileID,cj.Code,ap.Note,ap.WorkDate,ap.ActualHours as ActualHours1  from Att_ProfileTimeSheet ap  
left join Cat_JobType cj on cj.id=ap.JobTypeID  
where JobTypeID in (select id from Cat_JobType where Code in (''CongThieu'')) and ap.IsDelete is null) CC on CC.profileid=at.profileid and CC.WorkDate>=at.DateStart and CC.WorkDate<=at.DateEnd  
  
left join (select ProfileID,cj.Code,ap.Note,ap.WorkDate,ap.ActualHours from Att_ProfileTimeSheet ap  
left join Cat_JobType cj on cj.id=ap.JobTypeID  
where JobTypeID in (select id from Cat_JobType where Code in (''CongThua'')) and ap.IsDelete is null) CC1 on CC1.profileid=at.profileid and CC1.WorkDate>=at.DateStart and CC1.WorkDate<=at.DateEnd  
  
  --Vi pham thai san và tien phat khac  
Left join (select ProfileID,hd.DateOfEffective,cn.NameEntityName,sum(hd.AmountOfFine) as AmountOfFine,hd.Notes,DisciplineResonID,DateEndOfViolation from Hre_Discipline hd  
left join Cat_NameEntity cn on cn.ID=hd.DisciplineResonID and NameEntityType=''E_DISCIPLINE_REASON''  
where hd.IsDelete is null and cn.Code=2  
group by ProfileID,hd.DateOfEffective,cn.NameEntityName,hd.Notes,DisciplineResonID,DateEndOfViolation  
) PhatKhac on at.profileid = PhatKhac.profileid and at.DateStart<=PhatKhac.DateOfEffective and PhatKhac.DateEndOfViolation<=at.DateEnd  
  
Left join (select ProfileID,hd.DateOfEffective,cn.NameEntityName,hd.AmountOfFine,hd.Notes,DisciplineResonID,DateEndOfViolation from Hre_Discipline hd  
left join Cat_NameEntity cn on cn.ID=hd.DisciplineResonID and NameEntityType=''E_DISCIPLINE_REASON''  
where hd.IsDelete is null and cn.Code=1) VPTS on at.profileid = VPTS.profileid and at.DateStart>=VPTS.DateOfEffective and at.DateStart<=VPTS.DateEndOfViolation  
  
  left join (select ProfileID,at.ID,sum(ati.OvertimeHours/nullif(cs.StdWorkHours,0)) as OTT from Att_AttendanceTable at  
left join Att_AttendanceTableItem ati on at.id=ati.AttendanceTableID  
left join Cat_Shift cs on cs.id=ati.ShiftID  
where at.IsDelete is null  
group by ProfileID,at.ID) OTT on OTT.id=at.id  
  
  left JOIN Cat_OrgStructure co on co.id=at.OrgStructureID  
  LEFT JOIN Cat_Position cp on cp.id =at.PositionID  
  left outer join cat_shift cs1 on cs1.id = ati.ShiftID  
  left outer join cat_shift cs2 on cs2.id = ati.Shift2ID  
  left join Att_LeaveDay al on al.profileid=at.profileid and al.LeaveDayTypeID =(select id from Cat_LeaveDayType where Code=''TS'') and al.isdelete is null and at.monthyear>=al.datestart and at.monthyear<= al.dateend  
  
 left join (select ProfileID,AttendanceTableID,sum(TienPhatMuon) as Tien_Muon, sum(SoLanMuon) as SoLanMuon from   
(select   ( case  
   when aati.LateEarlyMinutes <=3 then 0  
   when aati.LateEarlyMinutes >3 and aati.LateEarlyMinutes <10  then 30000  
   when aati.LateEarlyMinutes >=10 and aati.LateEarlyMinutes <30 then 50000  
   when aati.LateEarlyMinutes >=30  then 100000  
   else 0  
   end  
  ) as TienPhatMuon  
  ,( case when aati.LateEarlyMinutes >3 then 1 else 0 end  
  ) as SoLanMuon  
    
    
 ,aat.ProfileID,aati.AttendanceTableID  
  from Att_AttendanceTableItem aati  
left join Att_AttendanceTable aat on aati.AttendanceTableID=aat.ID and aat.IsDelete is null  
where aat.ProfileID is not null) aaa  
group by ProfileID,AttendanceTableID) TienMuon on TienMuon.AttendanceTableID=at.id and TienMuon.ProfileID=at.ProfileID  
   
 left join (select AttendanceTableID,count(id) as SL_ThieuInOut from Att_AttendanceTableItem   
where MissInOutReasonID not in (select id from Cat_TAMScanReasonMiss where Code in(''QCC01'',''QCC04'',''QCC05'',''QCC07''))  
and MissInOutReasonID is not null  
group by AttendanceTableID) MissInOut on at.id=MissInOut.AttendanceTableID  
left join (select AttendanceTableID as ID,STRING_AGG(concat(DATEPART(DAY,WorkDate),''/'',DATEPART(MONTH,WorkDate)),'','') MuonSom  
from Att_AttendanceTableItem  
where IsDelete is null  
and AttendanceTableID in (select id from Att_AttendanceTable where IsDelete is null and monthyear=''2021-09-01'')  
and LateEarlyMinutes>3  
group by AttendanceTableID) MS on at.id = MS.id  
left join (select AttendanceTableID as ID,STRING_AGG(concat(DATEPART(DAY,WorkDate),''/'',DATEPART(MONTH,WorkDate)),'','') ThieuInOut  
from Att_AttendanceTableItem  
where IsDelete is null  
and AttendanceTableID in (select id from Att_AttendanceTable where IsDelete is null and monthyear=''2021-09-01'')  
and MissInOutReasonID is not null  
group by AttendanceTableID) IO on at.id = IO.id  
--Canteen  
left join (select cms.ProfileID,DATEADD(month, DATEDIFF(month, 0, TimeLog), 0) as Thang,count (cms.id) SL1  
,STRING_AGG(concat('' '',DATEPART(DAY,TimeLog),''/'',DATEPART(MONTH,TimeLog)),'','') DienGiai1  
from Can_MealRecord cms  
left join Can_MealBillEmployee cm on cm.ProfileID=cms.ProfileID and cm.DateMeal=DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) and cm.MealUnitID is null and cm.isdelete is null and (cm.Status is null or cm.Status<>''E_CANCEL'')  
where cms.IsDelete is null  
and cm.id is null  
and cms.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB'',''SANGLOCHM''))  
group by cms.ProfileID,DATEADD(month, DATEDIFF(month, 0, TimeLog), 0)  
) KoDK_CoAn on at.MonthYear=KoDK_CoAn.Thang and at.ProfileID=KoDK_CoAn.ProfileID  
  
left join (select cm.ProfileID,DATEADD(month, DATEDIFF(month, 0, cm.DateMeal), 0) Thang,count(cm.id) SL2   
,STRING_AGG(concat('' '',DATEPART(DAY,DateMeal),''/'',DATEPART(MONTH,DateMeal)),'','') DienGiai2  
from Can_MealBillEmployee cm  
left join (select ProfileID,DATEADD(dd, 0, DATEDIFF(dd, 0, TimeLog)) as Ngay ,TimeLog,MachineCode  
   from Can_MealRecord   
   where IsDelete is null) QuetThe on QuetThe.ProfileID=cm.ProfileID and QuetThe.Ngay=cm.DateMeal  
where cm.IsDelete is null and QuetThe.TimeLog is null  and cm.MealUnitID is null  
and (cm.Status is null or cm.Status<>''E_CANCEL'')  
and cm.CanteenID not in (select id from can_Canteen where CanteenCode  in (''SANGLOCPTM'',''SANGLOCYN'',''SANGLOCLB'',''SANGLOCHM''))  
group by cm.ProfileID, DATEADD(month, DATEDIFF(month, 0, cm.DateMeal), 0)  
) CoDK_KhongAn on at.MonthYear=CoDK_KhongAn.Thang and at.ProfileID=CoDK_KhongAn.ProfileID  
  
  
  
  where at.IsDelete is NULL and hp.codeemp is not null   
  ) temp pivot (MAX(temp.Cong ) for temp.Ngay in ([C16],[C17],[C18],[C19],[C20],[C21],[C22],[C23],[C24],[C25],[C26],[C27],[C28],[C29],[C30],[C31]  
  ,[C1],[C2],[C3],[C4],[C5],[C6],[C7],[C8],[C9],[C10],[C11],[C12],[C13],[C14],[C15])) as pvtbl  
 where CodeEmp is not null  
 ) abc where CodeEmp is not null  
  
  
 ' + @condition + 'select * from #Results'  
  
SET @queryPageSize = '  ALTER TABLE #Results ADD TotalRow int  
declare @totalRow int  
SELECT @totalRow = COUNT(*) FROM #Results  
update #Results set TotalRow = @totalRow  
SELECT * FROM #Results WHERE RowNumber BETWEEN(' + CAST(@PageIndex AS VARCHAR) + ' -1) * ' + CAST(@PageSize AS VARCHAR) + ' + 1 AND(((' + CAST(@PageIndex AS VARCHAR) + ' -1) * ' + CAST(@PageSize AS VARCHAR) + ' + 1) + ' + CAST(@PageSize AS VARCHAR) + ') -
 1  
DROP TABLE #Results  
 DROP TABLE #temp  
 DROP TABLE #temp1  
'  
EXEC (@query)  
PRINT (@query)  
PRINT (@queryPageSize)  
  
PRINT (@queryPageSize)  
END  
  
-- rpt_BangCongHangThang
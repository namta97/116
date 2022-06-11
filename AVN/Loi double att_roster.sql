
select * from Att_Roster where ProfileID = 'F8B0EA24-E395-4DD5-BCDC-0416CF1F2533' and DateStart = '2022-05-18 00:00:00.000'


select distinct ProfileID from (
select a.id, ROW_NUMBER() OVER(PARTITION BY a.ProfileID,a.DateStart ORDER BY a.Dateupdate DESC) AS rk, a.ProfileID
from Att_Roster a
inner join Att_shiftscheduledetail b
on a.ProfileID = b.ProfileID and coalesce(MonShiftID,TueShiftID,WedShiftID,ThuShiftID,FriShiftID,SatShiftID,SunShiftID)  = b.ShiftID
and a.DateStart = b.Date
inner join Att_ShiftSchedule c
on c.id = b.SheetID 
where a.IsDelete is null and a.DateStart = a.DateEnd and a.DateStart between '2022-04-21' and '2022-05-20'
and b.IsDelete is null and c.IsDelete is null and c.Status = 'E_APPROVED'
) kkkk
where kkkk.rk > 1


--update llll set llll.IsDelete =  1 , IPCreate = 'namta.del.2705'
--from (
--select a.id, ROW_NUMBER() OVER(PARTITION BY a.ProfileID,a.DateStart ORDER BY a.Dateupdate DESC) AS rk, a.ProfileID
--from Att_Roster a
--inner join Att_shiftscheduledetail b
--on a.ProfileID = b.ProfileID and coalesce(MonShiftID,TueShiftID,WedShiftID,ThuShiftID,FriShiftID,SatShiftID,SunShiftID)  = b.ShiftID
--and a.DateStart = b.Date
--inner join Att_ShiftSchedule c
--on c.id = b.SheetID 
--where a.IsDelete is null and a.DateStart = a.DateEnd and a.DateStart between '2022-04-21' and '2022-05-20'
--and b.IsDelete is null and c.IsDelete is null and c.Status = 'E_APPROVED'
--) kkkk
--inner join Att_Roster llll on llll.id = kkkk.ID
--where kkkk.rk > 1 
----order by llll.ProfileID





select * from Att_Roster where ProfileID ='65F2A9F1-4767-4794-B875-010E76B7A843' and IsDelete is null and DateStart = '2022-05-11 00:00:00.000'


select a.ProfileID,Date, count(*) from Att_shiftscheduledetail a
inner join Att_ShiftSchedule b
on a.SheetID=  b.id
where a.isdelete is null and b.IsDelete is null and b.Status = 'E_APPROVED'
group by a.ProfileID,Date having count(*) > 1
order by a.Date desc


--update  aa set aa.IsDelete = 1 , IPCreate = 'namta.del.2705'
--from (
--select ROW_NUMBER() OVER(PARTITION BY a.ProfileID,a.SheetID,a.date ORDER BY a.Dateupdate DESC) AS rk,a.*
--from Att_shiftscheduledetail a
--inner join Att_ShiftSchedule b
--on a.SheetID=  b.id
--where a.isdelete is null and b.IsDelete is null and b.Status = 'E_APPROVED' 
--) kk
--inner join Att_shiftscheduledetail aa on aa.id = kk.id
--where kk.rk > 1


select *
from (
select ROW_NUMBER() OVER(PARTITION BY a.ProfileID,a.SheetID,a.date ORDER BY a.Dateupdate DESC) AS rk,a.*
from Att_shiftscheduledetail a
inner join Att_ShiftSchedule b
on a.SheetID=  b.id
where a.isdelete is null and b.IsDelete is null and b.Status = 'E_APPROVED' 
) kk
where kk.rk > 1



select * from Att_shiftscheduledetail where SheetID = 'A5A21F65-0431-4E6A-9EB2-1FCB267C5010' and ProfileID = '00953102-2DC2-4B45-9360-05208869E19A' and IsDelete is null order by Date

select b.* from Att_shiftscheduledetail a
inner join Att_ShiftSchedule b on a.SheetID=  b.id
where a.profileid = '061A1A8B-FDC3-47C2-87FB-47B892CDF083' and Date = '2022-05-15 00:00:00.000' and a.IsDelete is null


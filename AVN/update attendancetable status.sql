

select UserApproveID,* 
--into Nam_Status_Att_AttendanceTable

from Att_AttendanceTable where  IsDelete IS NULL and MonthYear = '2022-04-01'


--update Att_AttendanceTable set IsDelete = 1, IPCreate = 'namta.del.2604' where  IsDelete IS NULL and MonthYear = '2022-04-01'

begin tran

--update a set a.UserApproveID = b.UserApproveID, a.UserApproveID2 = b.UserApproveID2, a.UserApproveID3 = b.UserApproveID3,a.UserApproveID4  = b.UserApproveID4 from Att_AttendanceTable a inner join Nam_Status_Att_AttendanceTable b 

--on a.profileID = b.profileID
--where
--a.IsDelete IS NULL and a.MonthYear = '2022-04-01' 
--AND ( b.status = 'E_SUBMIT' OR b.status = 'E_APPROVED'  )


--update Att_AttendanceTable set Status = 'E_APPROVED', SendEmailStatus = 'E_APPROVED',UserApproveID = '2C657D23-1409-4F1F-8B53-4CB6A43D3EFD', UserApproveID2 = '2C657D23-1409-4F1F-8B53-4CB6A43D3EFD', UserApproveID3 = '2C657D23-1409-4F1F-8B53-4CB6A43D3EFD', UserApproveID4 = '2C657D23-1409-4F1F-8B53-4CB6A43D3EFD', UserSubmitID = '5E6E1A05-BA92-41D0-ABA6-A3F87A388421' where ProfileID IN ( SELECT ID FROM dbo.Hre_Profile WHERE CodeEmp  = '20110627002'  AND IsDelete IS NULL) AND IsDelete IS NULL and MonthYear = '2022-04-01'
--update Att_AttendanceTable set Status = 'E_APPROVED', SendEmailStatus = 'E_APPROVED',UserApproveID = '03C6DBD4-5BC4-41E8-9FBB-72C85E3479C5', UserApproveID2 = '03C6DBD4-5BC4-41E8-9FBB-72C85E3479C5', UserApproveID3 = '03C6DBD4-5BC4-41E8-9FBB-72C85E3479C5', UserApproveID4 = '03C6DBD4-5BC4-41E8-9FBB-72C85E3479C5', UserSubmitID = '1A8CE06B-98AF-422C-BD19-73694E66F87A' where ProfileID IN ( SELECT ID FROM dbo.Hre_Profile WHERE CodeEmp  = '20010502001'  AND IsDelete IS NULL) AND IsDelete IS NULL and MonthYear = '2022-04-01'



select * from Att_AttendanceTable where ProfileID IN ( SELECT ID FROM dbo.Hre_Profile WHERE CodeEmp  = '20110627002'  AND IsDelete IS NULL)  and MonthYear = '2022-04-01' order by DateUpdate desc

select IsDelete,* from Att_AttendanceTable where ProfileID IN ( SELECT ID FROM dbo.Hre_Profile WHERE CodeEmp  = '20140908027'  AND IsDelete IS NULL) and MonthYear = '2022-04-01' order by Status



select * from (
select distinct Status from Att_AttendanceTable  ) a order by status


select a.IsDelete,a.Status, att.Status,att.UserApproveID,* from Att_AttendanceTable a

outer apply (


select top (1) * from Att_AttendanceTable b
where a.ProfileID = b.ProfileID
and a.MonthYear = b.MonthYear
order by b.status
) att
where a.ProfileID IN ( SELECT ID FROM dbo.Hre_Profile WHERE CodeEmp  = '20140908027'  AND IsDelete IS NULL) and a.MonthYear = '2022-04-01' and a.IsDelete is null


--update a set a.Status = att.Status, a.SendEmailStatus = att.SendEmailStatus, a.UserApproveID = att.UserApproveID, a.DateApprove = att.DateApprove,  IPCreate = 'namta.update.status2704' from Att_AttendanceTable a

--outer apply (


--select top (1) * from Att_AttendanceTable b
--where a.ProfileID = b.ProfileID
--and a.MonthYear = b.MonthYear
--order by b.status
--) att
--where a.MonthYear = '2022-04-01' and a.IsDelete is null


--update  Att_AttendanceTable  set UserApproveID2 = UserApproveID, UserApproveID3 = UserApproveID, UserApproveID4 = UserApproveID where MonthYear = '2022-04-01' and IsDelete is null



select UserApproveID,* from Att_AttendanceTable where profileiD = '1BBA72F2-873C-4420-8EBA-042DACF28474' and IsDelete IS NULL and MonthYear = '2022-04-01'

select UserApproveID,* from Att_AttendanceTable where id = 'CAA7959E-AF4C-40A6-B2C4-005EAA4387DC'

rollback

select UserApproveID,* from Nam_Status_Att_AttendanceTable where profileiD = '55928299-59BA-44E7-A4E0-044F3AE5DD6C'


select a.status,b.Status,a.SendEmailStatus, b.SendEmailStatus,b.UserApproveID,b.UserApproveID2, b.UserApproveID3,b.UserApproveID4,* from Att_AttendanceTable a left join Nam_Status_Att_AttendanceTable b
on a.profileID = b.profileID
where
a.IsDelete IS NULL and a.MonthYear = '2022-04-01'
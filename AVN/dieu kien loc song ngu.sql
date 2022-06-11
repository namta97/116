SELECT b.PivotTableName,* FROM dbo.Sys_PivotTableCondition a
LEFT JOIN dbo.Sys_PivotTable b ON a.PivotTableID = b.ID
WHERE NameColumn = 'spt.WorkPlaceID'





--select * from Sys_PivotTable 
--where SQLCommand = 'rpt_WorkingOnLunarNewYear'

--update Sys_PivotTableCondition set NameColumn = REPLACE(NameColumn,'aop.','condi.') where  PivotTableID = '78AF3FB5-0435-49C9-A703-1BD540E9203D'


--update Sys_PivotTableCondition set NameColumn = 'condi.EmpStatus' where id = '181F0B97-64AD-4170-90E3-BC34CBA89167'

--update Sys_PivotTableCondition set NameColumn = 'CodeEmp' where id = '7FAA3673-021B-4BAE-9443-D657CCA161D8'


--update Sys_PivotTableCondition set NameColumn = 'hp.Datehire' where id = 'B8AF486E-55CD-42A6-A3C2-15EEBB993ECE'
--update Sys_PivotTableCondition set NameColumn = 'hp.DateQuit' where id = 'BC1A0156-0EAA-4C85-88A5-28F297505E60'



--select * from Sys_PivotTableCondition where PivotTableID = '78AF3FB5-0435-49C9-A703-1BD540E9203D'



select * from Sys_PivotTable where id in (
select PivotTableID from Sys_PivotTableCondition where NameColumn like '%GradeAttendanceID%' 
)




select * from Sys_PivotTableCondition where NameColumn like '%condi.EmployeeGroupID%'

DECLARE @LanguageCode varchar(20)
--set @LanguageCode = 'VN'




----LaborType
--SELECT DISTINCT EnumKey,CASE WHEN @LanguageCode = 'VN' THEN VN ELSE EN END AS LaborType FROM Cat_EnumTranslate WHERE EnumName = 'LaborType' AND IsDelete IS NULL and EnumKey <> 'E_OTHER' ORDER BY EnumKey DESC
update dbo.Sys_PivotTableCondition SET SqlCombo = 'SELECT DISTINCT EnumKey,CASE WHEN @LanguageCode = ''VN'' THEN VN ELSE EN END AS LaborType FROM Cat_EnumTranslate WHERE  EnumName = ''LaborType'' AND IsDelete IS NULL and EnumKey <> ''E_OTHER'' ORDER BY EnumKey DESC '
WHERE NameColumn = 'condi.LaborType'


----EmployeeGroupID
--SELECT a.ID, CASE WHEN @LanguageCode = 'VN' THEN a.NameEntityName ELSE ISNULL(b.NameEntityName,a.NameEntityName) END AS NameEntityName FROM dbo.Cat_NameEntity a LEFT JOIN dbo.Cat_NameEntity_Translate b ON a.ID = b.OriginID WHERE a.EnumType ='E_EMPLOYEEGROUP' AND a.IsDelete IS NULL AND b.IsDelete IS NULL ORDER BY NameEntityName
update dbo.Sys_PivotTableCondition SET SqlCombo = 'SELECT a.ID, CASE WHEN @LanguageCode = ''VN'' THEN a.NameEntityName ELSE ISNULL(b.NameEntityName,a.NameEntityName) END AS NameEntityName  FROM dbo.Cat_NameEntity a LEFT JOIN dbo.Cat_NameEntity_Translate b ON a.ID = b.OriginID WHERE a.EnumType =''E_EMPLOYEEGROUP'' AND a.IsDelete IS NULL AND b.IsDelete IS NULL ORDER BY NameEntityName '
WHERE NameColumn = 'condi.EmployeeGroupID'

----WorkPlaceID
--SELECT a.ID, CASE WHEN @LanguageCode = 'VN' THEN a.WorkPlaceName ELSE ISNULL(b.WorkPlaceName,a.WorkPlaceName) END AS WorkPlaceName FROM dbo.Cat_WorkPlace a LEFT JOIN dbo.Cat_WorkPlace_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL ORDER BY WorkPlaceName
update dbo.Sys_PivotTableCondition SET SqlCombo = 'SELECT a.ID, CASE WHEN @LanguageCode = ''VN'' THEN a.WorkPlaceName ELSE ISNULL(b.WorkPlaceName,a.WorkPlaceName) END AS WorkPlaceName   FROM dbo.Cat_WorkPlace a LEFT JOIN dbo.Cat_WorkPlace_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL ORDER BY WorkPlaceName '
WHERE NameColumn = 'condi.WorkPlaceID'

----JobTitleID
--SELECT a.ID, CASE WHEN @LanguageCode = 'VN' THEN a.JobTitleName ELSE ISNULL(b.JobTitleName,a.JobTitleName) END AS JobTitleName FROM dbo.Cat_JobTitle a LEFT JOIN dbo.Cat_JobTitle_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL ORDER BY JobTitleName
update dbo.Sys_PivotTableCondition SET SqlCombo = 'SELECT a.ID, CASE WHEN @LanguageCode = ''VN'' THEN a.JobTitleName ELSE ISNULL(b.JobTitleName,a.JobTitleName) END AS JobTitleName FROM dbo.Cat_JobTitle a LEFT JOIN dbo.Cat_JobTitle_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL ORDER BY JobTitleName '
WHERE NameColumn = 'condi.JobTitleID'


----PositionID
--SELECT a.ID, CASE WHEN @LanguageCode = 'VN' THEN a.PositionName ELSE ISNULL(b.PositionName,a.PositionName) END AS PositionName FROM dbo.Cat_Position a LEFT JOIN dbo.Cat_Position_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL ORDER BY PositionName
update dbo.Sys_PivotTableCondition SET SqlCombo = 'SELECT a.ID, CASE WHEN @LanguageCode = ''VN'' THEN a.PositionName ELSE ISNULL(b.PositionName,a.PositionName) END AS PositionName FROM dbo.Cat_Position a LEFT JOIN dbo.Cat_Position_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL ORDER BY PositionName '
WHERE NameColumn = 'condi.PositionID'


----EmploymentType
--SELECT DISTINCT EnumKey, CASE WHEN @LanguageCode = 'VN' THEN VN ELSE EN END AS Name FROM Cat_EnumTranslate WHERE IsDelete IS NULL AND EnumName = 'EmploymentType' ORDER BY Name
UPDATE dbo.Sys_PivotTableCondition SET SqlCombo = 'SELECT DISTINCT EnumKey, CASE WHEN @LanguageCode = ''VN'' THEN VN ELSE EN END AS Name FROM Cat_EnumTranslate WHERE IsDelete IS NULL AND EnumName = ''EmploymentType'' ORDER BY Name '
WHERE NameColumn = 'condi.EmploymentType'

----- SalaryClassID
--SELECT a.ID, CASE WHEN @LanguageCode = 'VN' THEN CONCAT(a.SalaryClassName,' (',a.Code,')') ELSE CONCAT(b.SalaryClassName,' (',a.Code,')') END AS SalaryClassName FROM dbo.Cat_SalaryClass a LEFT JOIN dbo.Cat_SalaryClass_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL ORDER BY SalaryClassName
UPDATE dbo.Sys_PivotTableCondition SET SqlCombo = 'SELECT a.ID, CASE WHEN @LanguageCode = ''VN'' THEN CONCAT(a.SalaryClassName,'' ('',a.Code,'')'') ELSE CONCAT(b.SalaryClassName,'' ('',a.Code,'')'') END AS SalaryClassName FROM dbo.Cat_SalaryClass a LEFT JOIN dbo.Cat_SalaryClass_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL ORDER BY SalaryClassName '
WHERE NameColumn = 'condi.SalaryClassID'


----GradeAttendanceID
--SELECT a.ID, CASE WHEN @LanguageCode = 'VN' THEN a.GradeAttendanceName ELSE ISNULL(b.GradeAttendanceName,a.GradeAttendanceName) END AS GradeAttendanceName FROM dbo.Cat_GradeAttendance a LEFT JOIN dbo.Cat_GradeAttendance_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL ORDER BY GradeAttendanceName
UPDATE dbo.Sys_PivotTableCondition SET SqlCombo = 'SELECT a.ID, CASE WHEN @LanguageCode = ''VN'' THEN a.GradeAttendanceName ELSE ISNULL(b.GradeAttendanceName,a.GradeAttendanceName) END AS GradeAttendanceName FROM dbo.Cat_GradeAttendance a LEFT JOIN dbo.Cat_GradeAttendance_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL ORDER BY GradeAttendanceName '
WHERE NameColumn = 'ag.GradeAttendanceID'


--EmpStatus
--SELECT DISTINCT EnumKey,CASE WHEN @LanguageCode = 'VN' THEN VN ELSE EN END AS Name FROM dbo.Cat_EnumTranslate WHERE EnumName ='PayrollTableProfileStatus' AND EnumKey IN ('E_PROFILE_ACTIVE','E_PROFILE_QUIT','E_PROFILE_NEW') AND IsDelete IS NULL ORDER BY EnumKey 
UPDATE dbo.Sys_PivotTableCondition SET SqlCombo = 'SELECT DISTINCT EnumKey,CASE WHEN @LanguageCode = ''VN'' THEN VN ELSE EN END AS Name FROM dbo.Cat_EnumTranslate WHERE EnumName =''PayrollTableProfileStatus'' AND EnumKey IN (''E_PROFILE_ACTIVE'',''E_PROFILE_QUIT'',''E_PROFILE_NEW'') AND IsDelete IS NULL ORDER BY EnumKey  '
WHERE NameColumn = 'condi.EmpStatus'


----PayPaidType
--SELECT DISTINCT EN, CASE WHEN @LanguageCode = 'VN' THEN VN ELSE EN END AS PaymentType from Cat_EnumTranslate where  EnumName = 'UnusualPayPaidType' and IsDelete is NULL ORDER BY EN 
UPDATE dbo.Sys_PivotTableCondition SET SqlCombo = 'SELECT DISTINCT EN, CASE WHEN @LanguageCode = ''VN'' THEN VN ELSE EN END AS PaymentType from Cat_EnumTranslate where  EnumName = ''UnusualPayPaidType'' and IsDelete is NULL ORDER BY EN '
WHERE NameColumn = 'PayPaidType'

----CheckData
--SELECT DISTINCT EnumKey,CASE WHEN @LanguageCode = 'VN' THEN VN ELSE EN END AS Name from Cat_EnumTranslate where IsDelete IS NULL AND EnumName = 'CatNewsGroupType' AND EnumKey IN ('E_POSTS','E_UNEXPECTED') ORDER BY EnumKey 
UPDATE dbo.Sys_PivotTableCondition SET SqlCombo = 'SELECT DISTINCT EnumKey,CASE WHEN @LanguageCode = ''VN'' THEN VN ELSE EN END AS Name from Cat_EnumTranslate where IsDelete IS NULL AND EnumName = ''CatNewsGroupType'' AND EnumKey IN (''E_POSTS'',''E_UNEXPECTED'') ORDER BY EnumKey '
WHERE NameColumn = 'condi.EmpStatus'





-- Công tác
--abt.BusinessTripTypeID:
SELECT a.ID, CASE WHEN @LanguageCode = 'VN' THEN a.BusinessTravelName ELSE ISNULL(b.BusinessTravelName,a.BusinessTravelName) END AS BusinessTravelName FROM dbo.Cat_BusinessTravel a LEFT JOIN dbo.Cat_BusinessTravel_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL  AND b.IsDelete IS NULL ORDER BY BusinessTravelName
--t.StatusProfile:
SELECT EnumKey,CASE WHEN @LanguageCode = 'VN' THEN VN ELSE EN END AS Name FROM Cat_EnumTranslate WHERE IsDelete IS NULL AND EnumName = 'ProfileStatusSyn' AND ServerCreate =1 AND EnumKey IN ('E_HIRE','E_STOP') ORDER BY EnumKey

--Ngh? phép
--ald.LeaveTypeID
SELECT a.ID, CASE WHEN @LanguageCode = 'VN' THEN a.LeaveDayTypeName ELSE ISNULL(b.LeaveDayTypeName,a.LeaveDayTypeName) END AS LeaveDayTypeName FROM dbo.Cat_LeaveDayType a LEFT JOIN dbo.Cat_LeaveDayType_Translate b ON a.ID = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL ORDER BY LeaveDayTypeName

--Ch? d?: condi.PregnancyType
SELECT EnumKey, CASE WHEN @LanguageCode = 'VN' THEN VN ELSE EN END AS Name FROM Cat_EnumTranslate  WHERE ID IN ('D0C37F51-A435-44BF-B074-2F753647E43D','F92C0E5F-B253-4A2E-801B-541938165915') AND IsDelete IS NULL ORDER BY EnumKey

---OT: ao.DurationType
SELECT EnumKey, CASE WHEN @LanguageCode = 'VN' THEN VN ELSE EN END AS Name FROM Cat_EnumTranslate WHERE IsDelete IS NULL AND ID IN ('BC51B94B-0398-403E-9C4E-01BD32F91000','5BC98507-7D96-485F-9C67-0EA115618E26','90B0937B-5B58-4843-B0CD-0B613C14721E') ORDER BY EnumKey



select EnumKey, CASE WHEN @LanguageCode = 'VN' THEN VN ELSE EN END AS Name  from Cat_EnumTranslate where IsDelete is null and EnumName = 'TamScanLogType' and ID in ('6674839A-8328-4BE7-9DF8-0D54E19CC739','6622C63A-CD51-4F8E-A3C4-DD8F22FBB163')  ORDER BY EnumKey




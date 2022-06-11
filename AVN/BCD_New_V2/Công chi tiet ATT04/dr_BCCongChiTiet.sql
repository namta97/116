----Nam Ta: Bao cao Cong chi tiet thang, ung ( Bao cao nay tu tong hop cong )
ALTER proc dr_BCCongChiTietThang
@Condition NVARCHAR(MAX) = " and (MonthYear = '2022-02-01') ",
@PageIndex INT = 1,
@PageSize INT = 10000,
@Username VARCHAR(100) = 'khang.nguyen'
AS
BEGIN

DECLARE @LanguageID VARCHAR(2)
SELECT @LanguageID = CASE WHEN Value1 = 'VN' THEN 0 ELSE 1 END 
FROM dbo.Sys_AllSetting WHERE Value2 = @Username AND Name = 'HRM_SYS_USERSETTING_LANGUAGE' AND IsDelete IS NULL 
ORDER BY DateUpdate DESC OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY

--SET @LanguageID = 1

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

if ltrim(rtrim(@Condition)) = '' OR @Condition is null
    begin
            set @Top = ' top 0 ';
			SET @condition =  ' and (MonthYear = ''2022-02-01'') '
    END;

-- Condition
DECLARE @MonthYearCondition varchar(200) = ' '
DECLARE @MonthYear varchar(20) = ''
DECLARE @CheckData VARCHAR(500) =' '
DECLARE @EmpStatus VARCHAR(500) = ' '
DECLARE @TotalPaidDays VARCHAR(max) = '' 
DECLARE @IsAdvance VARCHAR(100) =''


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

	set @index = charindex('MonthYear = ',@tempID,0) 
	if(@index > 0)
	begin
		set @tempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @MonthYearCondition = @tempCondition
		SET @MonthYear = SUBSTRING(@MonthYearCondition, PATINDEX('%[0-9]%', @MonthYearCondition), 10);
	END
			
	set @index = charindex('(ProfileName ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
	END

	SET @index = CHARINDEX('(CodeEmp ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(CodeEmp ','(hp.CodeEmp ')
	END

	SET @index = CHARINDEX('(condi.EmploymentType ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.EmploymentType ','(hwh.EmploymentType ')
	END
    
	SET @index = CHARINDEX('(condi.SalaryClassID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.SalaryClassID ','(hwh.SalaryClassID ')
	END

	SET @index = CHARINDEX('(condi.PositionID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.PositionID ','(hwh.PositionID ')
	END
	
	SET @index = CHARINDEX('(condi.JobTitleID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.JobTitleID ','(hwh.JobTitleID ')
	END
	
	SET @index = CHARINDEX('(condi.WorkPlaceID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.WorkPlaceID ','(hwh.WorkPlaceID ')
	END
	
	SET @index = CHARINDEX('(condi.EmployeeGroupID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.EmployeeGroupID ','(hwh.EmployeeGroupID ')
	END
		
	SET @index = CHARINDEX('(condi.LaborType ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.LaborType ','(hwh.LaborType ')
	END		

	SET @index = CHARINDEX('CheckData ',@tempID,0)
	IF(@index > 0)
	BEGIN
		SET @TempCondition = 'and ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
		SET @CheckData = REPLACE(@TempCondition,'CheckData','')
		SET @CheckData = REPLACE(@CheckData,'like N','')
		SET @CheckData = REPLACE(@CheckData,'%','')
	END

	SET @index = CHARINDEX('(condi.EmpStatus ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @TempCondition = 'and ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
		SET @EmpStatus = REPLACE(@TempCondition,'(condi.EmpStatus IN ','')
		SET @EmpStatus = REPLACE(@EmpStatus,',',' OR ')
		SET @EmpStatus = REPLACE(@EmpStatus,'))',')')
	END

	SET @index = CHARINDEX('(TotalPaidDays ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @TempCondition = 'and ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
		SET @TotalPaidDays = @TempCondition
	END

	SET @index = CHARINDEX('(IsAdvance ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @TempCondition = 'and ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
		SET @IsAdvance = REPLACE(@TempCondition,' ','') 
	END


	DELETE #tableTempCondition WHERE ID = @ID
	SET @row = @row - 1

END

DECLARE @Count INT = 1;
declare @ListCol varchar(max);
declare @ListAlilas varchar(max);
declare @ListShiftCode varchar(max);
declare @ListShiftCode_First varchar(max);
declare @ListOverTimeType varchar(max);
declare @ListLeaveDayCode varchar(max);
declare @ListNoPaidLeaveDayCode varchar(max);
declare @ListPaidLeaveDayCode varchar(max);
declare @ListBusinessTravelCode varchar(max);
declare @ListBusinessTravelCode_First varchar(max);
DECLARE @Shift_Alias_BU VARCHAR(max);
DECLARE @Shift_Alias_BG VARCHAR(max);
DECLARE @Shift_Alias_I VARCHAR(max);
DECLARE @Shift_Alias_G VARCHAR(max);
DECLARE @Shift_Alias_BU_First VARCHAR(max);
DECLARE @Shift_Alias_BG_First VARCHAR(max);
DECLARE @Shift_Alias_I_First VARCHAR(max);
DECLARE @Shift_Alias_G_First VARCHAR(max);

select  @ListShiftCode = coalesce(@ListShiftCode + ',', '') + quotename(Code)
FROM	Cat_Shift
where   IsDelete is NULL
ORDER BY Code


SELECT  @ListShiftCode_First = coalesce(@ListShiftCode_First + ',', '') + quotename(Code + '_First') 
FROM	Cat_Shift
where   IsDelete is NULL
ORDER BY Code

select  @ListOverTimeType = coalesce(@ListOverTimeType + ',', '') + quotename(Code)
from    Cat_OvertimeType
where   IsDelete is NULL
ORDER BY Code

select  @ListLeaveDayCode = coalesce(@ListLeaveDayCode + ',', '') + quotename(Code)
from    Cat_LeaveDayType
where   IsDelete is NULL
ORDER BY Code

SET @ListLeaveDayCode = REPLACE(@ListLeaveDayCode,'HLD','H')


select  @ListPaidLeaveDayCode = coalesce(@ListPaidLeaveDayCode + ',', '') + quotename(Code)
from    Cat_LeaveDayType
where   IsDelete is null
        and PaidRate = 1
        and Code not in ('HLD')
ORDER BY Code

select  @ListNoPaidLeaveDayCode = coalesce(@ListNoPaidLeaveDayCode + ',', '') + quotename(Code)
from    Cat_LeaveDayType
where   IsDelete is null
        and (PaidRate = 0 OR PaidRate is null)
        and Code not in ('DL')			
ORDER BY Code;

select  @ListBusinessTravelCode = coalesce(@ListBusinessTravelCode + ',', '') + quotename(BusinessTravelCode)
from    Cat_BusinessTravel
where   IsDelete is NULL
ORDER BY BusinessTravelCode;

select  @ListBusinessTravelCode_First = coalesce(@ListBusinessTravelCode_First + ',', '') + quotename(BusinessTravelCode + '_First')
from    Cat_BusinessTravel
where   IsDelete is NULL
ORDER BY BusinessTravelCode;

select  @Shift_Alias_BU = coalesce(@Shift_Alias_BU + ' + ', '') + ' ISNULL(' + QUOTENAME(Code) + ',0)'
FROM	Cat_Shift 
WHERE	IsDelete IS NULL
		AND Code LIKE 'BU%'
SET @Shift_Alias_BU = ISNULL(@Shift_Alias_BU,'NULL') + ' AS BU'

select  @Shift_Alias_BU_First = coalesce(@Shift_Alias_BU_First + ' + ', '') + ' ISNULL(' + QUOTENAME(Code + '_First') + ',0)'
FROM	Cat_Shift 
WHERE	IsDelete IS NULL
		AND Code LIKE 'BU%'
SET @Shift_Alias_BU_First = ISNULL(@Shift_Alias_BU_First,'NULL') + ' AS BU_First'


select  @Shift_Alias_BG = coalesce(@Shift_Alias_BG + ' + ', '') + ' ISNULL(' + QUOTENAME(Code) + ',0)'
FROM	Cat_Shift 
WHERE	IsDelete IS NULL
		AND Code LIKE 'BG%'
SET @Shift_Alias_BG = ISNULL(@Shift_Alias_BG,'NULL') + ' AS BG'

select  @Shift_Alias_BG_First = coalesce(@Shift_Alias_BG_First + ' + ', '') + ' ISNULL(' + QUOTENAME(Code + '_First') + ',0)'
FROM	Cat_Shift 
WHERE	IsDelete IS NULL
		AND Code LIKE 'BG%'
SET @Shift_Alias_BG_First = ISNULL(@Shift_Alias_BG_First,'NULL') + ' AS BG_First'


select  @Shift_Alias_G = coalesce(@Shift_Alias_G + ' + ', '') + ' ISNULL(' + QUOTENAME(Code) + ',0)'
FROM	Cat_Shift 
WHERE	IsDelete IS NULL
		AND	Code LIKE 'G%'
SET @Shift_Alias_G = ISNULL(@Shift_Alias_G,'NULL') + ' AS G'


select  @Shift_Alias_G_First = coalesce(@Shift_Alias_G_First + ' + ', '') + ' ISNULL(' + QUOTENAME(Code + '_First') + ',0)'
FROM	Cat_Shift 
WHERE	IsDelete IS NULL
		AND	Code LIKE 'G%'
SET @Shift_Alias_G_First = ISNULL(@Shift_Alias_G_First,'NULL') + ' AS G_First'


select  @Shift_Alias_I = coalesce(@Shift_Alias_I + ' + ', '') + ' ISNULL(' + QUOTENAME(Code) + ',0)'
FROM	Cat_Shift 
WHERE	IsDelete IS NULL
		AND Code LIKE 'I%'
SET @Shift_Alias_I = ISNULL(@Shift_Alias_I,'NULL') + ' AS I'


select  @Shift_Alias_I_First = coalesce(@Shift_Alias_I_First + ' + ', '') + ' ISNULL(' + QUOTENAME(Code + '_First') + ',0)'
FROM	Cat_Shift 
WHERE	IsDelete IS NULL
		AND Code LIKE 'I%'
SET @Shift_Alias_I_First = ISNULL(@Shift_Alias_I_First,'NULL') + ' AS I_First'


--lay @DateStart, @DateEnd

DECLARE @DateStart date = (select top 1 DateStart from Att_CutOffDuration WHERE IsDelete is NULL AND MonthYear = @MonthYear );
DECLARE @DateEnd date = (select top 1 DateEnd from Att_CutOffDuration WHERE IsDelete is NULL AND MonthYear = @MonthYear );

--set @DateStart = '2022-03-01'
--set @DateEnd = '2022-03-31'

---Ngay ket thuc ky ung
DECLARE @UnusualDay INT
DECLARE @DateEndAdvance DATE
SELECT @UnusualDay = value1 from Sys_AllSetting where isdelete is null and Name like '%AL_Unusualpay_DaykeepUnusualpay%'
SET @DateEndAdvance = DATEADD(DAY,@UnusualDay -1,@MonthYear)

--SELECT @IsAdvance = 1
IF CHARINDEX('IsAdvance=1',@IsAdvance,0) > 0
BEGIN
	SET @DateEnd = @DateEndAdvance
END
  

declare @FirstDay date = @DateStart;
while @FirstDay <= @DateEnd
        begin
            set @ListCol = coalesce(@ListCol + ',', '') + quotename(@FirstDay);
            set @ListAlilas = coalesce(@ListAlilas + ',', '') + quotename(@FirstDay) + ' as Data' + convert(varchar(10), @Count);
            set @FirstDay = dateadd(day, 1, @FirstDay);
            set @Count += 1;
        end;


IF(@CheckData is not null and @CheckData <> '')
BEGIN
SET @index = charindex('E_POSTS',@CheckData,0) 
if(@index > 0)
BEGIN
SET @CheckData = REPLACE(@CheckData,'''E_POSTS''',' AgrProfileID IS NOT NULL ')
END
set @index = charindex('E_UNEXPECTED',@CheckData,0) 
if(@index > 0)
BEGIN
set @CheckData = REPLACE(@CheckData,'''E_UNEXPECTED''',' AgrProfileID IS NULL ')
END
END

---DK trang thai nhan vien
IF (@EmpStatus is not null and @EmpStatus <> '')
BEGIN
SET @index = charindex('E_PROFILE_NEW',@EmpStatus,0) 
IF(@index > 0)
BEGIN
SET @EmpStatus = REPLACE(@EmpStatus,'''E_PROFILE_NEW''',' (hp.DateHire <= @DateEnd AND hp.DateHire >= @DateStart ) ')
END
SET @index = charindex('E_PROFILE_ACTIVE',@EmpStatus,0) 
IF(@index > 0)
BEGIN
SET @EmpStatus = REPLACE(@EmpStatus,'''E_PROFILE_ACTIVE''','(hp.DateQuit IS NULL OR hp.DateQuit > @DateEnd)')
END
SET @index = charindex('E_PROFILE_QUIT',@EmpStatus,0)
IF(@index > 0)
BEGIN
SET @EmpStatus = REPLACE(@EmpStatus,'''E_PROFILE_QUIT''',' (hp.DateQuit <= @DateEnd AND hp.DateQuit >= @DateStart) ')	
END
END

-----Đk Ngay cong tra luong, vi BC tra ra 2 dong nen phai lam dk kieu nay
IF(@TotalPaidDays is not null and @TotalPaidDays <> '')
BEGIN
SELECT @TotalPaidDays = ' AND ProfileID IN ( SELECT ProfileID From Results WHERE 1 = 1 ' + @TotalPaidDays + ')'
END

------Co che do cong
--IF(@GradeAttendance is not null and @GradeAttendance <> '')
--BEGIN
--SELECT @GradeAttendance = ' AND ProfileID IN ( SELECT ProfileID From Results WHERE 1 = 1 ' + @GradeAttendance + ')'
--END

--SELECT @Condition, @CheckData

Set @ListLeaveDayCode = ISNULL(@ListLeaveDayCode,'')
Set @ListNoPaidLeaveDayCode = ISNULL(@ListNoPaidLeaveDayCode,'')
Set @ListPaidLeaveDayCode = ISNULL(@ListPaidLeaveDayCode,'')
Set @ListBusinessTravelCode = ISNULL(@ListBusinessTravelCode,'')
Set @ListCol = ISNULL(@ListCol,'')

declare @Getdata varchar(max);
declare @Query nvarchar(max);
declare @Query2 varchar(max);

-- Query chinh

set @Getdata = '
DECLARE @LanguageID INT = '+@LanguageID+'
declare @MonthYear date = ''' + @MonthYear + '''
declare @DateStart date = ''' + convert(varchar(20), @DateStart, 111) + ''';
declare @DateEnd date = ''' + convert(varchar(20), @DateEnd, 111) + ''';

-- Ham phan quyen
if object_id(''tempdb..#tblPermission'') is not null
   drop table #tblPermission;

CREATE TABLE #tblPermission (id uniqueidentifier primary key )
INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Att_WorkDay'''+'
print (''#tblPermission'');

-----Lay Ten tieng Anh Co cau truc thuoc-----------------

SELECT	OrgstructureID,E_BRANCH_CODE, E_UNIT_CODE, E_DIVISION_CODE, E_DEPARTMENT_CODE, E_TEAM_CODE
INTO	#UnitCode 
FROM	dbo.Cat_OrgUnit WHERE IsDelete IS NULL 

SELECT	a.ID AS OrgstructureID ,a.Code,a.OrderNumber, b.OrgStructureName, ROW_NUMBER() OVER(PARTITION BY a.Code ORDER BY a.DateUpdate DESC) AS rk	 
INTO	#NamEnglish1 
FROM	dbo.Cat_OrgStructure a LEFT JOIN dbo.Cat_OrgStructure_Translate b ON a.iD = b.OriginID WHERE a.IsDelete IS NULL AND b.IsDelete IS NULL

SELECT * INTO #NamEnglish FROM #NamEnglish1 WHERE rk= 1

SELECT		a.OrgstructureID, b.OrgStructureName AS DivisionName, c.OrgStructureName AS CenterName, d.OrgStructureName AS DepartmentName, e.OrgStructureName AS SectionName, f.OrgStructureName AS UnitName
			, b.OrderNumber AS DivisionOrder,  c.OrderNumber AS CenterOrder,  d.OrderNumber AS DepartmentOrder,  e.OrderNumber AS SectionOrder, f.OrderNumber AS UnitOrder
INTO		#NameEnglishORG
FROM		#UnitCode a
LEFT JOIN	#NamEnglish b
	ON		a.E_BRANCH_CODE = b.Code
LEFT JOIN	#NamEnglish c
	ON		a.E_UNIT_CODE = c.Code
LEFT JOIN	#NamEnglish d
	ON		a.E_DIVISION_CODE = d.Code
LEFT JOIN	#NamEnglish e
	ON		a.E_DEPARTMENT_CODE = e.Code
LEFT JOIN	#NamEnglish f
	ON		a.E_TEAM_CODE = f.Code

-- Lay du lieu qtct moi nhat trong thang
if object_id(''tempdb..#Hre_WorkHistory'') is not null 
	drop table #Hre_WorkHistory;
;WITH WorkHistory AS
(
select		' +@Top+ ' 
			*,ROW_NUMBER() OVER(PARTITION BY hwh.ProfileID ORDER BY hwh.DateEffective DESC) AS rk
from		Hre_WorkHistory as hwh
WHERE		hwh.IsDelete is null
			AND	hwh.DateEffective <= @DateEnd
			AND	hwh.Status = ''E_APPROVED''
) 
SELECT	*
INTO	#Hre_WorkHistory
FROM	WorkHistory 
WHERE	rk = 1
print(''#Hre_WorkHistory'');
'
set @Query = '
--- bang master data
if object_id(''tempdb..#TbWorkHistory'') is not null 
	drop table #TbWorkHistory;

select		' +@Top+ ' 
			hwh.ProfileID , hp.CodeEmp, hp.ProfileName
			'+ CASE WHEN @LanguageID = 0 
			THEN',cou.E_BRANCH AS DivisionName ,cou.E_UNIT AS CenterName,cou.E_DIVISION AS DepartmentName,cou.E_DEPARTMENT AS SectionName,cou.E_TEAM AS UnitName
			'
			ELSE
			'
			,ISNULL(neorg.DivisionName,E_BRANCH) AS DivisionName ,ISNULL(neorg.CenterName,E_UNIT) AS CenterName, ISNULL(neorg.DepartmentName,E_DIVISION) AS DepartmentName 
			,ISNULL(neorg.SectionName,E_DEPARTMENT) AS SectionName,ISNULL(neorg.UnitName,E_TEAM) AS UnitName
			'
			END
			+'
			,csc.SalaryClassName,cp.PositionName,cj.JobTitleName,CASE WHEN @LanguageID = 0 THEN cetl.VN ELSE ISNULL(cetl.EN,cetl.VN ) END AS EmploymentType
			,CASE WHEN @LanguageID = 0 THEN cetl2.VN ELSE ISNULL(cetl2.EN,cetl2.VN ) END AS LaborType ,cne.NameEntityName AS EmployeeGroupName, cwp.WorkPlaceName
			,hp.DateHire,hp.DateEndProbation,hp.DateQuit
			, @MonthYear as "MonthYear"
			,ag.GradeAttendanceID
INTO		#TbWorkHistory
from		#Hre_WorkHistory as hwh
INNER JOIN	hre_profile hp on hp.Id = hwh.ProfileID
LEFT JOIN	Cat_OrgStructure cos on cos.ID = hwh.OrganizationStructureID
LEFT JOIN	Cat_OrgUnit cou on cou.OrgstructureID = hwh.OrganizationStructureID
LEFT JOIN	Cat_SalaryClass csc on csc.ID = hwh.SalaryClassID
LEFT JOIN	Cat_JobTitle cj on cj.ID = hwh.JobTitleID
LEFT JOIN	Cat_Position cp on cp.ID = hwh.PositionID
LEFT JOIN	Cat_WorkPlace cwp on cwp.ID = hwh.WorkPlaceID
LEFT JOIN	Cat_NameEntity cne on cne.ID = hwh.EmployeeGroupID
LEFT JOIN	#NameEnglishORG neorg ON neorg.OrgStructureID = hwh.OrganizationStructureID
OUTER APPLY (
			SELECT	TOP(1) cetl.EN, cetl.VN
			FROM	Cat_EnumTranslate cetl
			WHERE	cetl.EnumKey = hwh.EmploymentType 
					AND cetl.EnumName = ''EmploymentType'' AND cetl.IsDelete is null
			ORDER BY DateUpdate DESC
			) cetl

OUTER APPLY (
			SELECT	TOP(1) cetl.EN, cetl.VN
			FROM	Cat_EnumTranslate cetl
			WHERE	cetl.EnumKey = hwh.LaborType 
					AND cetl.EnumName = ''LaborType'' AND cetl.IsDelete is null
			ORDER BY DateUpdate DESC
			) cetl2
OUTER APPLY
			(SELECT TOP(1) ag.GradeAttendanceID 
			FROM	dbo.Att_Grade ag
			WHERE	ag.ProfileID = hwh.ProfileID
					AND ag.MonthStart <= @DateEnd AND ( ag.MonthEnd IS NULL OR ag.MonthEnd >= @DateStart)
			ORDER BY ag.MonthStart DESC,ag.DateUpdate DESC
			) ag

WHERE		hp.IsDelete is null
	AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart)
	AND		hp.DateHire <= @DateEnd
	AND		exists (Select * from #tblPermission tpm where id = hp.id )
			' +ISNULL(@Condition,'')+ '
			' +ISNULL(@EmpStatus,'')+ '
'
set @Query2 = '
-- Lay du lieu bang tong hop cong
if object_id(''tempdb..#TbWorkday '') is not null 
	drop table #TbWorkday;
select ' +@Top+ '
		aw.ID
		,aw.ProfileID
		,aw.WorkDate
		,cs.ShiftCode
		,CASE WHEN cs.ShiftCode = ''2'' AND  LeaveDays1 IS NULL AND LeaveDays3 IS NULL AND ISNULL(BUSINESSDETAIL.BusinessDay1,0) + ISNULL(BUSINESSDETAIL.BusinessDay3,0) 
			+ CASE WHEN NOT (cga.AttendanceMethod = ''E_TAM'' AND ( aw.FirstInTime IS NULL OR aw.LastOutTime IS NULL or aw.LateEarlyDuration > 0)) AND ISNULL(BUSINESSDETAIL.BusinessDay3,0) = 0
			THEN 0.5 ELSE 0 END > 0 THEN 0.5

			WHEN cs.ShiftCode = ''3'' AND LeaveDays1 IS NULL AND LeaveDays2 IS NULL AND LeaveDays3 IS NULL AND NOT (cga.AttendanceMethod = ''E_TAM'' AND ( aw.FirstInTime IS NULL OR aw.LastOutTime IS NULL or aw.LateEarlyDuration > 0)) 
			THEN 7.5

			WHEN cs.ShiftCode = ''3'' AND LeaveDays1 IS NULL AND LeaveDays2 IS NULL AND ISNULL(BUSINESSDETAIL.BusinessDay1,0) + ISNULL(BUSINESSDETAIL.BusinessDay2,0) 
			+ CASE WHEN NOT (cga.AttendanceMethod = ''E_TAM'' AND ( aw.FirstInTime IS NULL OR aw.LastOutTime IS NULL or aw.LateEarlyDuration > 0)) AND ISNULL(BUSINESSDETAIL.BusinessDay1,0) + ISNULL(BUSINESSDETAIL.BusinessDay2,0) = 0
			THEN 0.5 ELSE 0 END > 0 THEN 4.0

			WHEN cs.ShiftCode = ''3'' AND LeaveDays1 IS NULL AND LeaveDays3 IS NULL AND ISNULL(BUSINESSDETAIL.BusinessDay1,0) + ISNULL(BUSINESSDETAIL.BusinessDay3,0) 
			+ CASE WHEN NOT (cga.AttendanceMethod = ''E_TAM'' AND ( aw.FirstInTime IS NULL OR aw.LastOutTime IS NULL or aw.LateEarlyDuration > 0)) AND ISNULL(BUSINESSDETAIL.BusinessDay1,0) + ISNULL(BUSINESSDETAIL.BusinessDay3,0) = 0
			THEN 0.5 ELSE 0 END > 0 THEN 3.5
		END AS NS1
		,CASE WHEN cs.ShiftCode is not null THEN 
		CASE WHEN ISNULL(LEAVEDETAIL.LeaveDays1,0) = 1 THEN 0
			WHEN ISNULL(BUSINESSDETAIL.BusinessDay1,0) = 1 THEN 1 - ( ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0) )
			WHEN ISNULL(BUSINESSDETAIL.BusinessDay1,0) = 0 AND ISNULL(LEAVEDETAIL.LeaveDays1,0) = 0 THEN
				CASE WHEN ISNULL(BUSINESSDETAIL.BusinessDay2,0) - ISNULL(LEAVEDETAIL.LeaveDays2,0) > 0 THEN  ISNULL(BUSINESSDETAIL.BusinessDay2,0) - ISNULL(LEAVEDETAIL.LeaveDays2,0) ELSE 0 END
				+ CASE WHEN  ISNULL(BUSINESSDETAIL.BusinessDay3,0) - ISNULL(LEAVEDETAIL.LeaveDays3,0) > 0 THEN ISNULL(BUSINESSDETAIL.BusinessDay3,0) - ISNULL(LEAVEDETAIL.LeaveDays3,0) ELSE 0 END
		END
		END AS BusinessDay
		,CASE WHEN cs.ShiftCode is not null THEN
			CASE WHEN cga.AttendanceMethod = ''E_TAM'' AND ( aw.FirstInTime IS NULL OR aw.LastOutTime IS NULL OR aw.LateEarlyDuration > 0) THEN 0
				WHEN ISNULL(LEAVEDETAIL.LeaveDays1,0) = 1 THEN 0
				WHEN ISNULL(BUSINESSDETAIL.BusinessDay1,0) = 1 THEN 0
				ELSE
					CASE WHEN 0.5 - ( ISNULL(BUSINESSDETAIL.BusinessDay2,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0) ) > 0 THEN 0.5 ELSE 0 END 
					+ CASE WHEN 0.5 - ( ISNULL(BUSINESSDETAIL.BusinessDay3,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0) ) > 0 THEN 0.5 ELSE 0 END
			END
		END AS WorkDays
		,CASE WHEN aw.DataType = ''E_INVALID'' THEN ''???''
		ELSE
			CASE WHEN cs.ShiftCode IS NOT NULL THEN
				CASE WHEN LEAVEDETAIL.LeaveCode1 is not null 
					THEN LEAVEDETAIL.LeaveCode1

					WHEN LEAVEDETAIL.LeaveCode2 is not NULL AND LEAVEDETAIL.LeaveCode3 is NULL
					THEN concat( LEAVEDETAIL.LeaveDays2, LEAVEDETAIL.LeaveCode2, '' | '', 
						CASE WHEN BUSINESSDETAIL.BusinessCode1 IS NULL AND BUSINESSDETAIL.BusinessCode3 IS NULL AND cga.AttendanceMethod = ''E_TAM'' AND ( aw.FirstInTime IS NULL OR aw.LastOutTime IS NULL OR aw.LateEarlyDuration > 0) THEN ''!!!''
						ELSE ''0.5'' END , COALESCE(BUSINESSDETAIL.BusinessCode1,BUSINESSDETAIL.BusinessCode3,''Ca'' + cs.ShiftCode ))

					when LEAVEDETAIL.LeaveCode2 is NULL AND LEAVEDETAIL.LeaveCode3 is not null
					then concat(
						CASE WHEN BUSINESSDETAIL.BusinessCode1 IS NULL AND BUSINESSDETAIL.BusinessCode2 IS NULL AND cga.AttendanceMethod = ''E_TAM'' AND ( aw.FirstInTime IS NULL OR aw.LastOutTime IS NULL OR aw.LateEarlyDuration > 0) THEN ''!!!''
						ELSE ''0.5'' END , COALESCE(BUSINESSDETAIL.BusinessCode1,BUSINESSDETAIL.BusinessCode2,''Ca'' + cs.ShiftCode ),  '' | '',LEAVEDETAIL.LeaveDays3, LEAVEDETAIL.LeaveCode3 )

					when LEAVEDETAIL.LeaveCode2 is not null and LEAVEDETAIL.LeaveCode3 is not null
					then concat( LEAVEDETAIL.LeaveDays2 ,LEAVEDETAIL.LeaveCode2, '' | '',LEAVEDETAIL.LeaveDays3 , LEAVEDETAIL.LeaveCode3)

					WHEN BUSINESSDETAIL.BusinessCode1 IS NOT NULL 
					THEN BUSINESSDETAIL.BusinessCode1

					WHEN BUSINESSDETAIL.BusinessCode2 IS NOT NULL AND BUSINESSDETAIL.BusinessCode3 IS NULL
					THEN concat( BUSINESSDETAIL.BusinessDay2, BUSINESSDETAIL.BusinessCode2, '' | '', 
						CASE WHEN BUSINESSDETAIL.BusinessCode3 IS NULL AND cga.AttendanceMethod = ''E_TAM'' AND ( aw.FirstInTime IS NULL OR aw.LastOutTime IS NULL OR aw.LateEarlyDuration > 0) THEN ''!!!''
						ELSE ''0.5'' END , COALESCE(BUSINESSDETAIL.BusinessCode3,''Ca''+ cs.ShiftCode ))

					WHEN BUSINESSDETAIL.BusinessCode2 IS NULL AND BUSINESSDETAIL.BusinessCode3 IS NOT NULL
					THEN concat(
						CASE WHEN BUSINESSDETAIL.BusinessCode2 IS NULL AND cga.AttendanceMethod = ''E_TAM'' AND ( aw.FirstInTime IS NULL OR aw.LastOutTime IS NULL OR aw.LateEarlyDuration > 0) THEN ''!!!''
						ELSE ''0.5'' END , COALESCE(BUSINESSDETAIL.BusinessCode2,''Ca'' + cs.ShiftCode ),  '' | '', BUSINESSDETAIL.BusinessDay3, BUSINESSDETAIL.BusinessCode3 )

					WHEN BUSINESSDETAIL.BusinessCode2 IS NOT NULL AND BUSINESSDETAIL.BusinessCode3 IS NOT NULL
					THEN concat( BUSINESSDETAIL.BusinessDay2, BUSINESSDETAIL.BusinessCode2, '' | '', BUSINESSDETAIL.BusinessDay3, BUSINESSDETAIL.BusinessCode3 )

					WHEN cga.AttendanceMethod = ''E_TAM'' AND ( aw.FirstInTime IS NULL OR aw.LastOutTime IS NULL OR aw.LateEarlyDuration > 0) THEN  ''!!!'' + ''Ca'' + cs.ShiftCode 
					ELSE ''Ca''+ cs.ShiftCode
				END
			WHEN cs.ShiftCode IS NULL AND LEAVEDETAIL.LeaveCode1 = ''H'' THEN LEAVEDETAIL.LeaveCode1
			END
		END AS Symbol
		,LEAVEDETAIL.*
		,BUSINESSDETAIL.*
		,CASE WHEN ISNULL(BUSINESSDETAIL.BusinessDay1,0) - (ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0)) > 0
			THEN ISNULL(BUSINESSDETAIL.BusinessDay1,0) - (ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0) ) END AS RealBusinessDay1
		,CASE WHEN ISNULL(BUSINESSDETAIL.BusinessDay2,0) - (ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0)) > 0
			THEN ISNULL(BUSINESSDETAIL.BusinessDay2,0) - (ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0) ) END AS RealBusinessDay2
		,CASE WHEN ISNULL(BUSINESSDETAIL.BusinessDay3,0) - (ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0)) > 0
			THEN ISNULL(BUSINESSDETAIL.BusinessDay3,0) - (ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0)) END AS RealBusinessDay3
		,aw.Status as WorkDayStatus
		,aw.Type
		,aw.DataType
		,ShiftID
into    #TbWorkday
from    Att_Workday as aw
        left join (select   ID
                          , Code as ShiftCode
                          , LeaveHoursFullShift
                          , LeaveHoursLastHalfShift
                          , LeaveHoursFirstHalfShift
                   from     Cat_Shift
                   where    IsDelete is null
                  ) as cs on cs.ID = aw.ShiftID  -- and aw.Status = ''E_CONFIRMED''

        outer apply (select top(1) ald.ID
						  , ald.ProfileID
                          , cldt.LeaveDayTypeCode
                          , ald.DurationType
                          , ald.LeaveDays
                          , ald.LeaveHours
                          , cldt.PaidRate
						  , convert(date, ald.DateStart,102) AS DateStart
						  , convert(date, ald.DateEnd,102) AS DateEnd
                     from   Att_LeaveDay as ald
                            left join (select   ID
                                              , Code as LeaveDayTypeCode
                                              , PaidRate
                                       from     Cat_LeaveDayType
                                       where    IsDelete is null
                                      ) as cldt on cldt.ID = ald.LeaveDayTypeID
                     where  ald.IsDelete is null
                            and ald.ProfileID = aw.ProfileID
                            and ald.Status = ''E_APPROVED''
							AND convert(date, aw.WorkDate,102) Between convert(date, ald.DateStart,102) AND convert(date, ald.DateEnd,102)
							AND aw.ShiftID IS NOT NULL
					order by ald.DateUpdate ASC, ald.ID ASC
                    ) as ld1
        outer apply (select top(1) ald.ID
                          , ald.ProfileID
                          , cldt.LeaveDayTypeCode
                          , ald.DurationType
                          , ald.LeaveDays
                          , ald.LeaveHours
                          , cldt.PaidRate
						  , convert(date, ald.DateStart,102) AS DateStart
						  , convert(date, ald.DateEnd,102) AS DateEnd
                     from   Att_LeaveDay as ald
                            left join (select   ID
                                              , Code as LeaveDayTypeCode
                                              , PaidRate
                                       from     Cat_LeaveDayType
                                       where    IsDelete is null
                                      ) as cldt on cldt.ID = ald.LeaveDayTypeID
                     where  ald.IsDelete is null
                            and ald.ProfileID = aw.ProfileID
                            and ald.Status = ''E_APPROVED''
							AND convert(date, aw.WorkDate,102) Between convert(date, ald.DateStart,102) AND convert(date, ald.DateEnd,102)
							AND aw.ShiftID IS NOT NULL
							AND  ald.ID <> ld1.ID
					order by ald.DateUpdate desc ,ald.ID desc
                    ) as lde
        outer apply (select top(1) abt.ID
                          , abt.ProfileID
                          , abt.DurationType
                          , cbt.BusinessTravelCode
						  , convert(date, abt.DateFrom,102)  AS DateFrom
						  , convert(date, abt.DateTo,102) AS DateTo
                     from   Att_BussinessTravel as abt
                            left join (select   ID
                                              , BusinessTravelCode
                                       from     Cat_BusinessTravel
                                       where    IsDelete is null
                                      ) as cbt on cbt.ID = abt.BusinessTripTypeID
                     where  abt.IsDelete is null
                            and abt.Status = ''E_APPROVED''
                            and abt.ProfileID = aw.ProfileID
							AND convert(date, aw.WorkDate,102) Between convert(date, abt.DateFrom,102) AND convert(date, abt.DateTo,102)
							AND ( ( aw.ShiftID IS NOT NULL AND cbt.BusinessTravelCode = ''WFH'') OR cbt.BusinessTravelCode <> ''WFH'' )
					order by abt.DateUpdate ASC,abt.ID ASC
                    ) as tbt1
        outer apply (select top(1) abt.ID
                          , abt.ProfileID
                          , abt.DurationType
                          , cbt.BusinessTravelCode
						  , convert(date, abt.DateFrom,102)  AS DateFrom
						  , convert(date, abt.DateTo,102) AS DateTo
                     from   Att_BussinessTravel as abt
                            left join (select   ID
                                              , BusinessTravelCode
                                       from     Cat_BusinessTravel
                                       where    IsDelete is null
                                      ) as cbt on cbt.ID = abt.BusinessTripTypeID
                     where  abt.IsDelete is null
                            and abt.Status = ''E_APPROVED''
                            and abt.ProfileID = aw.ProfileID
							AND convert(date, aw.WorkDate,102) Between convert(date, abt.DateFrom,102) AND convert(date, abt.DateTo,102)
							AND ( ( aw.ShiftID IS NOT NULL AND cbt.BusinessTravelCode = ''WFH'') OR cbt.BusinessTravelCode <> ''WFH'' )
							AND abt.ID <> tbt1.ID
					order by abt.DateUpdate desc,abt.ID desc
                    ) as tbt2
        left join (select   ID
                          , DateOff
                          , ''H'' as DayOffCode
                          , ''E_FULLSHIFT'' as DayOffDurationType
                          , 1 as DayOffPaidRate
                          , 1 as DayOffLeaveDays
                   from     Cat_DayOff
                   where    IsDelete is null
                            and Type = ''E_HOLIDAY''
                  ) as cdo on cdo.DateOff = aw.WorkDate
        cross apply (select case when cdo.DateOff is not null AND ( ld1.LeaveDayTypeCode IS NULL OR ( ld1.LeaveDayTypeCode NOT LIKE ''SIB%'' AND  ld1.LeaveDayTypeCode <> ''LS'' ) ) then ''E_FULLSHIFT-1.0-H'' end as DayOff
						,case when ld1.DurationType = ''E_FULLSHIFT'' or lde.DurationType = ''E_FULLSHIFT'' 
								OR ld1.DurationType = ''E_FIRST'' or lde.DurationType = ''E_FIRST'' 
								OR ld1.DurationType = ''E_FIRST_AND_LAST'' or lde.DurationType = ''E_FIRST_AND_LAST'' 
								OR ld1.DurationType = ''E_LAST'' or lde.DurationType = ''E_LAST''
								THEN
								CASE WHEN	 
									ld1.DurationType = ''E_FULLSHIFT''
									OR ( ld1.DateStart <> aw.WorkDate AND ld1.DurationType = ''E_FIRST'' ) 
									OR ( ld1.DateEND <> aw.WorkDate AND  ld1.DurationType = ''E_LAST'' ) 
									OR ( ld1.DateStart <> aw.WorkDate AND ld1.DateEND <> aw.WorkDate AND ld1.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(''E_FULLSHIFT'', ''-'', ''1.0'', ''-'', ld1.LeaveDayTypeCode)

									when lde.DurationType = ''E_FULLSHIFT'' 
									OR ( lde.DateStart <> aw.WorkDate AND  lde.DurationType = ''E_FIRST''  ) 
									OR ( lde.DateEnd <> aw.WorkDate AND  lde.DurationType = ''E_LAST''  ) 
									OR ( lde.DateStart <> aw.WorkDate AND lde.DateEND <> aw.WorkDate AND lde.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(''E_FULLSHIFT'', ''-'', ''1.0'', ''-'', lde.LeaveDayTypeCode)
								END
							end as FullShift_L

                          , case when ld1.DurationType = ''E_FIRSTHALFSHIFT'' or lde.DurationType = ''E_FIRSTHALFSHIFT'' 
								OR ld1.DurationType = ''E_LAST'' or lde.DurationType = ''E_LAST'' 
								OR ld1.DurationType = ''E_FIRST_AND_LAST'' or lde.DurationType = ''E_FIRST_AND_LAST''
								THEN
								CASE WHEN ld1.DateStart = aw.WorkDate AND ( ld1.DurationType = ''E_FIRSTHALFSHIFT'')
									then concat(ld1.DurationType, ''-'',''0.5'', ''-'', ld1.LeaveDayTypeCode)

									WHEN ld1.DateEnd = aw.WorkDate AND ( ld1.DurationType = ''E_LAST'' OR ld1.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(ld1.DurationType, ''-'',''0.5'', ''-'', ld1.LeaveDayTypeCode)

									when lde.DateStart = aw.WorkDate AND ( lde.DurationType = ''E_FIRSTHALFSHIFT'' )
									then concat(lde.DurationType, ''-'', ''0.5'', ''-'', lde.LeaveDayTypeCode)

									when lde.DateEnd = aw.WorkDate AND ( lde.DurationType = ''E_LAST'' OR lde.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(lde.DurationType, ''-'', ''0.5'', ''-'', lde.LeaveDayTypeCode)


								END
                            end as FirstShift_L

                          , case when ld1.DurationType = ''E_LASTHALFSHIFT'' or lde.DurationType = ''E_LASTHALFSHIFT'' 
								OR ld1.DurationType = ''E_FIRST'' or lde.DurationType = ''E_FIRST'' 
								OR ld1.DurationType = ''E_FIRST_AND_LAST'' or lde.DurationType = ''E_FIRST_AND_LAST''
								THEN
								CASE WHEN ld1.DateEnd = aw.WorkDate AND ( ld1.DurationType = ''E_LASTHALFSHIFT'')
									then concat(ld1.DurationType, ''-'', ld1.LeaveDays, ''-'', ld1.LeaveDayTypeCode)

									WHEN ld1.DateStart = aw.WorkDate AND ( ld1.DurationType = ''E_FIRST'' OR ld1.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(ld1.DurationType, ''-'', ld1.LeaveDays, ''-'', ld1.LeaveDayTypeCode)


									when lde.DateEnd = aw.WorkDate AND ( lde.DurationType = ''E_LASTHALFSHIFT'' )
									then concat(lde.DurationType, ''-'', lde.LeaveDays, ''-'', lde.LeaveDayTypeCode)

									when lde.DateStart = aw.WorkDate AND ( lde.DurationType = ''E_FIRST'' OR lde.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(lde.DurationType, ''-'', lde.LeaveDays, ''-'', lde.LeaveDayTypeCode)

								END
							end as LastShift_L
                    ) as LD

		cross apply ( SELECT
						case when tbt1.DurationType = ''E_FULLSHIFT'' OR tbt2.DurationType = ''E_FULLSHIFT''
								OR  tbt1.DurationType = ''E_FIRST'' OR tbt2.DurationType = ''E_FIRST''
								OR  tbt1.DurationType = ''E_FIRST_AND_LAST'' OR tbt2.DurationType = ''E_FIRST_AND_LAST''
								OR  tbt1.DurationType = ''E_LAST'' OR tbt2.DurationType = ''E_LAST''
								THEN
								CASE WHEN
									tbt1.DurationType = ''E_FULLSHIFT'' 
									OR ( tbt1.DateFrom <> aw.WorkDate AND  tbt1.DurationType = ''E_FIRST''  ) 
									OR ( tbt1.DateTo <> aw.WorkDate AND tbt1.DurationType = ''E_LAST''  ) 
									OR ( tbt1.DateFrom <> aw.WorkDate AND tbt1.DateTo <> aw.WorkDate AND tbt1.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(''E_FULLSHIFT'', ''-'', ''1.0'', ''-'', tbt1.BusinessTravelCode)
											
									WHEN
									tbt2.DurationType = ''E_FULLSHIFT'' 
									OR ( tbt2.DateFrom <> aw.WorkDate AND  tbt2.DurationType = ''E_FIRST'' )
									OR ( tbt2.DateTo <> aw.WorkDate AND tbt2.DurationType = ''E_LAST'' ) 
									OR ( tbt2.DateFrom <> aw.WorkDate AND tbt2.DateTo <> aw.WorkDate AND tbt2.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(''E_FULLSHIFT'', ''-'', ''1.0'', ''-'', tbt2.BusinessTravelCode)
								END

							end as FullShift_B
                          , case when tbt1.DurationType = ''E_FIRSTHALFSHIFT'' or tbt2.DurationType = ''E_FIRSTHALFSHIFT''
								OR tbt1.DurationType = ''E_LAST'' or tbt2.DurationType = ''E_LAST''
								OR tbt1.DurationType = ''E_FIRST_AND_LAST'' or tbt2.DurationType = ''E_FIRST_AND_LAST''
								THEN
								CASE WHEN	
									tbt1.DateFrom = aw.WorkDate AND ( tbt1.DurationType = ''E_FIRSTHALFSHIFT'')
									then concat(tbt1.DurationType, ''-'', ''0.5'', ''-'', tbt1.BusinessTravelCode)

									when tbt1.DateTo = aw.WorkDate AND (tbt1.DurationType = ''E_LAST'' OR tbt1.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(tbt1.DurationType, ''-'', ''0.5'', ''-'', tbt1.BusinessTravelCode)

									when tbt2.DateFrom = aw.WorkDate AND ( tbt2.DurationType = ''E_FIRSTHALFSHIFT''  )
									then concat(tbt2.DurationType, ''-'', ''0.5'', ''-'', tbt2.BusinessTravelCode)

									when tbt2.DateTo = aw.WorkDate AND ( tbt2.DurationType = ''E_LAST'' OR tbt2.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(tbt2.DurationType, ''-'', ''0.5'', ''-'', tbt2.BusinessTravelCode)
								END

                            end as FirstShift_B
                          , case when tbt1.DurationType = ''E_LASTHALFSHIFT'' or tbt2.DurationType = ''E_LASTHALFSHIFT''
								OR tbt1.DurationType = ''E_FIRST'' or tbt2.DurationType = ''E_FIRST''
								OR tbt1.DurationType = ''E_FIRST_AND_LAST'' or tbt2.DurationType = ''E_FIRST_AND_LAST''
								THEN
								CASE WHEN	
									tbt1.DateTo = aw.WorkDate AND ( tbt1.DurationType = ''E_LASTHALFSHIFT''  )
									then concat(tbt1.DurationType, ''-'', ''0.5'', ''-'', tbt1.BusinessTravelCode)

									when tbt1.DateFrom = aw.WorkDate AND (tbt1.DurationType = ''E_FIRST'' OR tbt1.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(tbt1.DurationType, ''-'', ''0.5'', ''-'', tbt1.BusinessTravelCode)

									when tbt2.DateTo = aw.WorkDate AND ( tbt2.DurationType = ''E_LASTHALFSHIFT'' )
									then concat(tbt2.DurationType, ''-'', ''0.5'', ''-'', tbt2.BusinessTravelCode)

									when tbt2.DateFrom = aw.WorkDate AND ( tbt2.DurationType = ''E_FIRST'' OR tbt2.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(tbt2.DurationType, ''-'', ''0.5'', ''-'', tbt2.BusinessTravelCode)
								END
							end as LastShift_B
                    ) as BT

        cross apply (SELECT	CASE WHEN LD.DayOff IS NOT NULL THEN LD.DayOff ELSE  LD.FullShift_L END as StringLeaveCode1
                          ,CASE WHEN LD.DayOff IS NULL THEN LD.FirstShift_L END as StringLeaveCode2
						  ,CASE WHEN LD.DayOff IS NULL THEN LD.LastShift_L END as StringLeaveCode3
                    ) LEAVE

        cross apply (SELECT
                           	CASE WHEN LD.DayOff IS NULL THEN BT.FullShift_B END AS StringBusinessCode1
                          ,CASE WHEN LD.DayOff IS NULL THEN  BT.FirstShift_B END as StringBusinessCode2
						  ,CASE WHEN LD.DayOff IS NULL THEN BT.LastShift_B END as StringBusinessCode3
                    ) BUSINESS

        cross apply (select left(LEAVE.StringLeaveCode1, charindex(''-'', LEAVE.StringLeaveCode1) - 1) as DurationType1
                          , left(LEAVE.StringLeaveCode2, charindex(''-'', LEAVE.StringLeaveCode2) - 1) as DurationType2
						  , left(LEAVE.StringLeaveCode3, charindex(''-'', LEAVE.StringLeaveCode3) - 1) as DurationType3
                          , right(LEAVE.StringLeaveCode1, charindex(''-'', reverse(LEAVE.StringLeaveCode1)) - 1) as LeaveCode1
                          , right(LEAVE.StringLeaveCode2, charindex(''-'', reverse(LEAVE.StringLeaveCode2)) - 1) as LeaveCode2
						  , right(LEAVE.StringLeaveCode3, charindex(''-'', reverse(LEAVE.StringLeaveCode3)) - 1) as LeaveCode3
                          , case when left(LEAVE.StringLeaveCode1, charindex(''-'', LEAVE.StringLeaveCode1) - 1) = ''E_FULLSHIFT'' then 1
							end as LeaveDays1
                          , case when left(LEAVE.StringLeaveCode2, charindex(''-'', LEAVE.StringLeaveCode2) - 1) IN (''E_FIRSTHALFSHIFT'',''E_LAST'',''E_FIRST_AND_LAST'' ) then 0.5
							end as LeaveDays2
						  , case when left(LEAVE.StringLeaveCode3, charindex(''-'', LEAVE.StringLeaveCode3) - 1) IN ( ''E_LASTHALFSHIFT'',''E_FIRST'',''E_FIRST_AND_LAST'' ) then 0.5
							end as LeaveDays3
                    ) LEAVEDETAIL
        cross apply (select left(BUSINESS.StringBusinessCode1, charindex(''-'', BUSINESS.StringBusinessCode1) - 1) as B_DurationType1
                          , left(BUSINESS.StringBusinessCode2, charindex(''-'', BUSINESS.StringBusinessCode2) - 1) as B_DurationType2
						  , left(BUSINESS.StringBusinessCode3, charindex(''-'', BUSINESS.StringBusinessCode3) - 1) as B_DurationType3
                          , right(BUSINESS.StringBusinessCode1, charindex(''-'', reverse(BUSINESS.StringBusinessCode1)) - 1) as BusinessCode1
                          , right(BUSINESS.StringBusinessCode2, charindex(''-'', reverse(BUSINESS.StringBusinessCode2)) - 1) as BusinessCode2
						  , right(BUSINESS.StringBusinessCode3, charindex(''-'', reverse(BUSINESS.StringBusinessCode3)) - 1) as BusinessCode3
                          , case when left(BUSINESS.StringBusinessCode1, charindex(''-'', BUSINESS.StringBusinessCode1) - 1) = ''E_FULLSHIFT'' then 1
							end as BusinessDay1
                          , case when left(BUSINESS.StringBusinessCode2, charindex(''-'', BUSINESS.StringBusinessCode2) - 1) IN (''E_FIRSTHALFSHIFT'',''E_LAST'',''E_FIRST_AND_LAST'' ) then 0.5
							end as BusinessDay2
						  , case when  left(BUSINESS.StringBusinessCode3, charindex(''-'', BUSINESS.StringBusinessCode3) - 1) IN ( ''E_LASTHALFSHIFT'',''E_FIRST'',''E_FIRST_AND_LAST'' ) then 0.5
							end as BusinessDay3
                    ) BUSINESSDETAIL
		OUTER APPLY
				(SELECT TOP(1) ag.GradeAttendanceID
				FROM	dbo.Att_Grade ag
				WHERE	ag.ProfileID = aw.ProfileID
						AND ag.MonthStart <= @DateEnd AND ( ag.MonthEnd IS NULL OR ag.MonthEnd >= @DateStart)
				ORDER BY ag.MonthStart DESC,ag.DateUpdate DESC
				) ag
		LEFT JOIn	Cat_GradeAttendance cga
			ON		cga.ID = ag.GradeAttendanceID

where   aw.IsDelete is null
        and aw.WorkDate between @DateStart and @DateEnd
        and exists ( select * from   #TbWorkHistory as twh where  twh.ProfileID = aw.ProfileID );
print (''#TbWorkday'');



--Sum du lieu OT theo tung ngay cua moi nv  
if object_id(''tempdb..#Att_Overtime_Sum'') is not null  
   drop table #Att_Overtime_Sum;  
  
SELECT  ' + @Top + '
		ProfileID, WorkDateRoot, Status, SUM(ConfirmHours) AS ConfirmHours_Sum  
INTO	#Att_Overtime_Sum  
FROM	Att_Overtime ao
WHERE	WorkDateRoot between @DateStart and @DateEnd  
   and	Status = ''E_CONFIRM'' AND IsDelete is null  
   and	exists ( select * from #TbWorkHistory as twh where twh.ProfileID = ao.ProfileID )
GROUP BY ProfileID, WorkDateRoot, Status


-- Lay du lieu OT
if object_id(''tempdb..#TbOvertime'') is not null
   drop table #TbOvertime;
select		' + @Top + '
			ao.ID
			,tw.ProfileID
			,ISNULL(ao.WorkDateRoot,tw.WorkDate) AS WorkDateRoot
			,cot.OvertimeTypeCode
			,ao.ConfirmHours
			,CASE WHEN tw.DataType = ''E_INVALID'' THEN ''???'' 
				WHEN tw.LeaveCode1 =''H'' THEN ISNULL(CONVERT(VARCHAR(10),aos.ConfirmHours_Sum), '' '') 
				WHEN tw.ShiftID IS NOT NULL THEN ISNULL(CONVERT(VARCHAR(10),aos.ConfirmHours_Sum),'' '') 
			ELSE CONVERT(VARCHAR(10),aos.ConfirmHours_Sum)
			END AS ConfirmHours_TB
			,tw.DataType
into		#TbOvertime
from		#TbWorkday tw
LEFT JOIN	Att_Overtime as ao
			ON tw.ProfileID = ao.ProfileID AND tw.WorkDate = ao.WorkDateRoot
			and ao.Status = ''E_CONFIRM'' and ao.WorkDateRoot between @DateStart and @DateEnd AND ao.IsDelete is null
LEFT JOIN	#Att_Overtime_Sum as aos
			ON tw.ProfileID = aos.ProfileID AND tw.WorkDate = aos.WorkDateRoot
left join	(select   ID, Code as OvertimeTypeCode
			from     Cat_OvertimeType
			where    IsDelete is null
			) as cot on cot.ID = ao.OvertimeTypeID
where		exists ( select * from #TbWorkHistory as twh where twh.ProfileID = tw.ProfileID );
print (''#TbOvertime'');

--select * from #TbOvertime ORDER BY WorkDateRoot desc

-- Pivot du lieu chi tiet
if object_id(''tempdb..#TbDetail'') is not null
   drop table #TbDetail;
select  *
into    #TbDetail
from    (select pv.ProfileID AS ProfileID_td
              , 1 as OrderNumber
			  , CASE WHEN dbo.fnc_NumberOfExceptWeekends(@DateStart,@DateEnd) > 22 THEN 22 ELSE dbo.fnc_NumberOfExceptWeekends(@DateStart,@DateEnd) END as "STDWorkingDays"
              , ' + @ListAlilas + '
         from   (select wh.ProfileID
                      , tw.WorkDate
                      , tw.Symbol
                 from (select distinct ProfileID from #TbWorkHistory) as wh
				 left join #TbWorkday as tw on tw.ProfileID = wh.ProfileID
                 where  1 = 1
                ) as data pivot ( max(Symbol) for WorkDate in (' + @ListCol + ') ) as pv
         union all
         select pv.ProfileID
              , 2 as OrderNumber
			  , null as "STDWorkingDays"
              , ' + @ListAlilas + '
         from   (select wh.ProfileID
                      , tov.WorkDateRoot
                      , tov.ConfirmHours_TB
                 from   (select distinct ProfileID from #TbWorkHistory) as wh
                        left join #TbOvertime as tov on tov.ProfileID = wh.ProfileID
                 where  1 = 1
                ) as data pivot ( max(ConfirmHours_TB) for WorkDateRoot in (' + @ListCol + ') ) as pv
        ) as D
print (''#TbDetail'');

-- Sum du lieu ngay cong
if object_id(''tempdb..#TbSumShift'') is not null
   drop table #TbSumShift;
select  *
into    #TbSumShift
from    (select tw.ProfileID AS ProfileID_tss
              , tw.ShiftCode
              , tw.WorkDays
         from   #TbWorkday as tw
         where  tw.DataType = ''E_VALID''
        ) as Data pivot ( sum(WorkDays) for ShiftCode in (' + @ListShiftCode + ') ) as pv;
print (''#TbSumShift'');


-- Sum du lieu cong tac
if object_id(''tempdb..#TbSumBusinessLeave'') is not null
   drop table #TbSumBusinessLeave;
select *
		, ' + replace(replace(replace(@ListBusinessTravelCode, ',', '+'), '[', 'isnull(['), ']', '],0)')
                + ' 			
----Update - WFH			
				- isnull([WFH],0) as TotalBusinessTravelDays
into    #TbSumBusinessLeave
from    (select		tw.ProfileID AS ProfileID_tsbl, BT.*
		from		#TbWorkday as tw
		cross apply ( values ( tw.BusinessCode1, convert(float, tw.RealBusinessDay1)), ( tw.BusinessCode2, convert(float, tw.RealBusinessDay2)), ( tw.BusinessCode3, convert(float, tw.RealBusinessDay3)) ) as BT (BusinessCode, BusinessDay)
		where		BT.BusinessCode in (' + replace(replace(@ListBusinessTravelCode, '[', ''''), ']', '''') + ')
					AND tw.ShiftID IS NOT NULL AND tw.DataType = ''E_VALID''
        ) as Data pivot ( sum(BusinessDay) for BusinessCode in (' + @ListBusinessTravelCode + ') ) as pv;
print (''#TbSumBusinessLeave'');


-- Sum du lieu ngay nghi
if object_id(''tempdb..#TbSumLeaveDay'') is not null
   drop table #TbSumLeaveDay;
select  *
		, ' + replace(replace(replace(@ListPaidLeaveDayCode, ',', '+'), '[', 'isnull(['), ']', '],0)') + ' as TotalPaidLeaveDay
		, ' + replace(replace(replace(@ListNoPaidLeaveDayCode, ',', '+'), '[', 'isnull(['), ']', '],0)')+ ' as TotalNoPaidLeaveDay
into    #TbSumLeaveDay
from    (select		tw.ProfileID AS ProfileID_tsld, LD.*
		from		#TbWorkday as tw
		cross apply ( values ( tw.LeaveCode1, convert(float, tw.LeaveDays1)), ( tw.LeaveCode2, convert(float, tw.LeaveDays2)) , ( tw.LeaveCode3, convert(float, tw.LeaveDays3)) ) as LD (LeaveCode, LeaveDays)
        where		LD.LeaveCode in (' + replace(replace(@ListLeaveDayCode, '[', ''''), ']', '''') + ') 
					AND ( tw.ShiftID IS NOT NULL OR tw.LeaveCode1 =''H'') AND tw.DataType = ''E_VALID''
        ) as Data pivot ( sum(LeaveDays) for LeaveCode in (' + @ListLeaveDayCode + ') ) as pv;
print (''#TbSumLeaveDay'');


-- Sum du lieu tang ca
if object_id(''tempdb..#TbSumOT'') is not null
   drop table #TbSumOT;
select  ProfileID AS ProfileID_tso
      , nullif(isnull(E_WORKDAY, 0) + isnull(E_WORKDAY_NIGHTSHIFT, 0),0) as OT1
      , nullif(isnull(E_WEEKEND, 0) + isnull(E_WEEKEND_NIGHTSHIFT, 0),0) as OT2
      , nullif(isnull(E_HOLIDAY, 0) + isnull(E_HOLIDAY_NIGHTSHIFT, 0),0) as OT2H
      , nullif(isnull(E_HOLIDAY, 0) + isnull(E_WEEKEND_NIGHTSHIFT, 0) + isnull(E_WORKDAY_NIGHTSHIFT, 0) + isnull(E_WORKDAY, 0) + isnull(E_HOLIDAY_NIGHTSHIFT, 0)
        + isnull(E_WEEKEND, 0),0) as TotalOT
	  , E_WORKDAY_NIGHTSHIFT as NS2
	  , E_WEEKEND_NIGHTSHIFT as NS3
	  , E_HOLIDAY_NIGHTSHIFT as NS4
into    #TbSumOT
from    (select tov.ProfileID
              , tov.OvertimeTypeCode
              , tov.ConfirmHours
         from   #TbOvertime as tov
         where  tov.DataType = ''E_VALID''
        ) as Data pivot ( sum(ConfirmHours) for OvertimeTypeCode in (' + @ListOverTimeType + ') ) as pv;

print (''#TbSumOT'');


-- Sum gio lam ca dem, ngay lam viec
if object_id(''tempdb..#TbSumWorkDay'') is not null
   drop table #TbSumWorkDay;
select  tw.ProfileID AS ProfileID_tswd
      , sum(tw.WorkDays) as TotalWorkDays
	  , count(tw.ID) as TotalWD
	  , sum(case when tw.DataType = ''E_VALID'' then 1 end) as TotalWD_VALID
	  , sum(case when tw.DataType = ''E_INVALID'' then 1 end) as TotalWD_INVALID
	  , sum(case when tw.WorkDayStatus = ''E_CONFIRMED'' then 1 end) as TotalWDConfirmed
	  --, sum(case when tw.WorkDayStatus = ''E_WAIT_CONFIRMED'' then 1 end) as TotalWDWaitConfirmed
	  --, sum(case when tw.WorkDayStatus is null then 1 end) as TotalWDNull
	  , sum(case when tw.WorkDayStatus is null then 1 end) as UnLockDataWorkday
	  , sum(case when tw.WorkDayStatus = ''E_WAIT_CONFIRMED'' then 1 end) as LockedDataWorkday
into    #TbSumWorkDay
from    #TbWorkday as tw
group by tw.ProfileID;
print (''#TbSumWorkDay'');

----SumNightShiftHours
if object_id(''tempdb..#SumNightShiftHours'') is not null
   drop table #SumNightShiftHours;

SELECT	ProfileID, SUM(NS1) AS NS1
INTO	#SumNightShiftHours
FROM	#TbWorkday tw
WHERE	tw.ShiftID IS NOT NULL AND tw.DataType = ''E_VALID''
GROUP BY ProfileID

---Count ngay co ca lam viec
if object_id(''tempdb..#TbCountHaveShift'') is not null
   drop table #TbCountHaveShift;

Select	tw.ProfileID,Count(*) AS CountHaveShift
into    #TbCountHaveShift
from    #TbWorkday as tw
WHERE	tw.ShiftID IS NOT NULL OR tw.LeaveCode1 = ''H''
		
group by tw.ProfileID;
print (''#TbCountHaveShift'');

-- Sum du lieu ngay cong co di lam nua ca truoc
if object_id(''tempdb..#TbSumShift_First'') is not null
   drop table #TbSumShift_First;
select  *
into    #TbSumShift_First
from    (select tw.ProfileID AS ProfileID_tssf
              , tw.ShiftCode + ''_First'' AS ShiftCode
              , tw.WorkDays
         from   #TbWorkday as tw
         where  tw.DataType = ''E_VALID'' AND tw.Symbol NOT LIKE ''!!!%'' AND tw.LeaveCode1 IS NULL AND tw.LeaveCode2 IS NULL
        ) as Data pivot ( Count(WorkDays) for ShiftCode in (' + @ListShiftCode_First + ') ) as pv;
print (''#TbSumShift_First'');


-- Sum du lieu cong tac co di cong tac nua ca truoc
if object_id(''tempdb..#TbSumBusinessLeave_First'') is not null
   drop table #TbSumBusinessLeave_First;
select *
into    #TbSumBusinessLeave_First
from    (select		tw.ProfileID AS ProfileID_tsblf, BT.*
		from		#TbWorkday as tw
		cross apply ( values ( tw.BusinessCode1 + ''_First'', convert(float, tw.RealBusinessDay1)), ( tw.BusinessCode2 + ''_First'', convert(float, tw.RealBusinessDay2)), ( tw.BusinessCode3 + ''_First'', convert(float, tw.RealBusinessDay3)) ) as BT (BusinessCode, BusinessDay)
		where		BT.BusinessCode in (' + replace(replace(@ListBusinessTravelCode_First, '[', ''''), ']', '''') + ')
					AND tw.ShiftID IS NOT NULL AND tw.DataType = ''E_VALID'' AND tw.Symbol NOT LIKE ''!!!%'' AND tw.LeaveCode1 IS NULL AND tw.LeaveCode2 IS NULL
        ) as Data pivot ( Count(BusinessDay) for BusinessCode  in (' + @ListBusinessTravelCode_First + ') ) as pv;
print (''#TbSumBusinessLeave_First'');


--select * from #TbWorkday  order by workdate


-- Bang ket qua tong
;WITH Results AS
(
select  NULL AS STT
		,twh.*, td.*
		,' +@Shift_Alias_I+ '
		,ISNULL(E,0) AS E
		,' +@Shift_Alias_G+ '
		,' +@Shift_Alias_BG+ ' 
		,' +@Shift_Alias_BU+ ' 
		,ISNULL(D,0) AS D, ISNULL([1],0) AS Ca1, ISNULL([2],0) AS Ca2, ISNULL([3],0) AS Ca3
		,tsbl.*, tsld.*
		,' +@Shift_Alias_I_First+ '
		,ISNULL(E_First,0) AS E_First
		,' +@Shift_Alias_G_First+ '
		,' +@Shift_Alias_BG_First+ ' 
		,' +@Shift_Alias_BU_First+ '
		,ISNULL(D_First,0) AS D_First, ISNULL([1_First],0) AS Ca1_First, ISNULL([2_First],0) AS Ca2_First, ISNULL([3_First],0) AS Ca3_First
		,tsblf.*
		,isnull(tsld.TotalPaidLeaveDay,0) + isnull(tsld.H,0) + isnull(tswd.TotalWorkDays,0) + isnull(tsbl.TotalBusinessTravelDays,0) + isnull([WFH],0) as TotalPaidDays
		,isnull(tswd.TotalWorkDays,0) AS RealWorkDayCount
		,ISNULL(tswd.TotalWD,0) - ISNULL(tchs.CountHaveShift,0) AS TotalLeaveDayWeekly
		,tso.*
		,snsh.NS1
		,nullif(isnull(snsh.NS1,0) + ISNULL(tso.NS2,0) + ISNULL(tso.NS3,0) + ISNULL(tso.NS4,0) ,0) as TotalNS
		, tswd.*
		, CASE WHEN aat.Status IS NULL THEN dbo.GETENUMVALUE(''PayrollPaybackStatus'',''E_NOTCOMPUTE'', ''' + @Username + ''') 
			ELSE dbo.GETENUMVALUE(''ComputeAttendanceStatus'', aat.Status, ''' + @Username + ''') 
			END AS AttendanceStatus
		,@DateStart AS DateStart
		,@DateEnd AS DateEnd
		,GETDATE() AS DateExport
		,NULL AS "cos.OrderNumber",NULL AS "condi.EmploymentType",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID", NULL AS "hp.DateHire"
		,NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "condi.WorkPlaceID"
		,NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType"
		,NULL AS "condi.EmpStatus",NULL AS "CheckData", NULL AS ''ag.GradeAttendanceID''
		,NULL AS "IsAdvance"
		,Agr.ProfileID AS AgrProfileID
		,ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp,td.OrderNumber ) as RowNumber
from    #TbWorkHistory as twh
left join	#TbDetail td on td.ProfileID_td = twh.ProfileID
left join	#TbSumShift tss on tss.ProfileID_tss = twh.ProfileID and td.OrderNumber = 1
left join	#TbSumBusinessLeave tsbl on tsbl.ProfileID_tsbl = twh.ProfileID and td.OrderNumber = 1
left join	#TbSumLeaveDay tsld on tsld.ProfileID_tsld = twh.ProfileID and td.OrderNumber = 1
left join	#TbSumOT tso on tso.ProfileID_tso = twh.ProfileID and td.OrderNumber = 2
left join	#TbSumWorkDay tswd on tswd.ProfileID_tswd = twh.ProfileID and td.OrderNumber = 1
--left join #TbSumWorkDay tswd2 on tswd2.ProfileID_tswd = twh.ProfileID and td.OrderNumber = 1
left join	#TbCountHaveShift tchs on tchs.ProfileID = twh.ProfileID and td.OrderNumber = 1
left join	#SumNightShiftHours snsh on snsh.ProfileID = twh.ProfileID and td.OrderNumber = 2
left join	#TbSumShift_First tssf on tssf.ProfileID_tssf = twh.ProfileID and td.OrderNumber = 1
left join	#TbSumBusinessLeave_First tsblf on tsblf.ProfileID_tsblf = twh.ProfileID and td.OrderNumber = 1
OUTER APPLY (SELECT Status FROM Att_AttendanceTable aat WHERE aat.ProfileID = twh.ProfileID AND aat.MonthYear = @MonthYear AND aat.IsDelete IS NULL) aat
OUTER APPLY ( SELECT TOP (1) agr.ProfileID FROM att_grade agr where agr.ProfileID = twh.ProfileID AND agr.MonthStart < @DateEnd AND agr.isdelete IS null ORDER BY agr.MonthStart DESC ) Agr
)
select * 
INTO	#Results
from	Results
where	1= 1 '+@TotalPaidDays+' '+@CheckData+' 

Select	RowNumber,ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as STT
INTO	#TempSTT
from	#Results
where	OrderNumber = 1

UPDATE		r
SET			r.STT = temp.STT
FROM		#Results r
INNER JOIN	#TempSTT temp 
	ON		r.RowNumber = temp.RowNumber

SELECT * FROM #Results
order by RowNumber

drop table #TbDetail, #TbOvertime, #tblPermission, #TbSumBusinessLeave, #TbSumLeaveDay, #TbSumOT, #TbSumShift, #TbSumWorkDay, #TbWorkday, #Hre_WorkHistory, #TbWorkHistory, #TempSTT, #Results;
Drop table #SumNightShiftHours
DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG

';

DECLARE @Strlang VARCHAR(5) = CAST(@LanguageID AS CHAR(1));  
IF (@LanguageID > 0  AND EXISTS   
	(  
	SELECT 1  
	FROM dbo.Sys_AllSetting  
	WHERE IsDelete IS NULL  
	AND Name = 'HRM_SYS_CATEGORYTRANSLATIONCONFIGURATION'  
	AND Value1 = 'True'  
	)
)
 
BEGIN  
DECLARE @queryWhereLang NVARCHAR(MAX) = @Query;  
BEGIN TRY  

SELECT		ColumnName, TableDefault, TableTranslate  
INTO		#TableColumnTranslate  
FROM		dbo.View_GetTableTranslate

SELECT		ColumnName, TableDefault, TableTranslate  
INTO		#tblTempTranslate  
FROM		#TableColumnTranslate  
WHERE		@Query LIKE '%' + TableDefault + '%'
	AND		TableDefault <> 'Cat_EnumTranslate'

DECLARE @strCondition VARCHAR(MAX) = NULL;  
DECLARE @strConditionTranslate VARCHAR(500) = NULL;  

WHILE (EXISTS (SELECT 1 FROM #tblTempTranslate))  
BEGIN  
DECLARE @i VARCHAR(100) =  
( SELECT TOP (1) TableDefault FROM #tblTempTranslate 
)

SET @strCondition = NULL;  
SET @strConditionTranslate = NULL;  

SELECT		@strConditionTranslate = COALESCE(@strConditionTranslate + ',', '') + cb.ColumnName  
FROM		#tblTempTranslate cb  
WHERE		cb.TableDefault = @i;

SET	@strCondition = 'ID, Code, ISNULL(ColumnCustom.' + @strConditionTranslate + ', ColumnDefault.'+@strConditionTranslate+') AS '+@strConditionTranslate+',IsDelete'

--- Lay ít cột cho đỡ rối, nếu cần cột thêm thì làm tương tự bên dưới IF
IF @i = 'Cat_SalaryClass'
BEGIN
SET @strCondition += ', AbilityTitleID '
END

IF @i = 'Cat_OrgStructure'
BEGIN
SET @strCondition += ', OrderNumber '
END

DECLARE @sqlQueryCustom VARCHAR(MAX)  

SET @sqlQueryCustom= N' 
(
SELECT	'+ @strCondition + N' 
FROM	dbo.' + @i + ' ColumnDefault WITH(NOLOCK) 
LEFT JOIN (SELECT OriginID, ' + @strConditionTranslate+ ' FROM dbo.' + @i + '_Translate WHERE IsDelete IS NULL AND LanguageID = ' +@Strlang+ ' ) ColumnCustom 
	ON	ColumnCustom.OriginID = ColumnDefault.ID WHERE ColumnDefault.IsDelete IS null 
) ';  
SET @Query = ( SELECT dbo.RegexReplaceTable(@Query, @i, @sqlQueryCustom) );  

DELETE #tblTempTranslate  
WHERE TableDefault = @i;  
END;  
DROP TABLE #tblTempTranslate,  
#TableColumnTranslate;  
END TRY  
BEGIN CATCH  
SET @Query = @queryWhereLang; 
END CATCH; 
END;  

exec (@Getdata + @Query + @Query2);
			
--PRINT(@Getdata)
--Set @Query = replace(replace(@Query, char(13) + char(10), char(10)), char(13), char(10));
--while len(@Query) > 1
--	begin
--		if charindex(char(10), @Query) between 1 and 4000
--			begin
--                    set @CurrentEnd = charindex(char(10), @Query) - 1;
--                    set @Offset = 2;
--			end;
--		else
--			begin
--                    set @CurrentEnd = 4000;
--                    set @Offset = 1;
--		end;   
--			print substring(@Query, 1, @CurrentEnd); 
--			set @Query = substring(@Query, @CurrentEnd + @Offset, len(@Query));   
--	end;

--Set @Query2 = replace(replace(@Query2, char(13) + char(10), char(10)), char(13), char(10));
--while len(@Query2) > 1
--	begin
--		if charindex(char(10), @Query2) between 1 and 4000
--			begin
--                    set @CurrentEnd = charindex(char(10), @Query2) - 1;
--                    set @Offset = 2;
--			end;
--		else
--			begin
--                    set @CurrentEnd = 4000;
--                    set @Offset = 1;
--		end;   
--			print substring(@Query2, 1, @CurrentEnd); 
--			set @Query2 = substring(@Query2, @CurrentEnd + @Offset, len(@Query2));   
--	end;

--dr_BCCongChiTietThang
end;

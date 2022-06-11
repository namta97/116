----Nam Ta: Bao cao Tam tinh luong ngay cong
ALTER proc rpt_TempBasicSalary
@Condition nvarchar(max) = " and (MonthYear = '2022-02-01') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'khang.nguyen'
AS
BEGIN

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
	end;

-- Condition
DECLARE @MonthYearCondition varchar(200) = ' '
DECLARE @MonthYear varchar(20) = ''
DECLARE @CheckData NVARCHAR(500) =' '
DECLARE @EmStatus NVARCHAR(500) = ' '
DECLARE @GradeAttendance NVARCHAR(max) = '' 
DECLARE @TotalPaidDays NVARCHAR(max) = '' 
DECLARE @TotalDL NVARCHAR(max) = '' 

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
		set @MonthYear = substring(@MonthYearCondition, patindex('%[0-9]%', @MonthYearCondition), 10);
	END
				
	set @index = charindex('(ProfileName ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
	END

	set @index = charindex('CheckData ',@tempID,0)
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @CheckData = REPLACE(@TempCondition,'CheckData','')
		set @CheckData = REPLACE(@CheckData,'like N','')
		set @CheckData = REPLACE(@CheckData,'%','')
	END

	set @index = charindex('(EmpStatus ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @EmStatus = REPLACE(@TempCondition,'(EmpStatus IN ','')
		set @EmStatus = REPLACE(@EmStatus,',',' OR ')
		set @EmStatus = REPLACE(@EmStatus,'))',')')
	END

	set @index = charindex('(GradeAttendanceID ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @GradeAttendance = @TempCondition
	END

	SET @index = charindex('(TotalPaidDays ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @TotalPaidDays = REPLACE(@TempCondition,'(TotalPaidDays in ','')
		set @TotalPaidDays = REPLACE(@TotalPaidDays,',',' OR ')
		set @TotalPaidDays = REPLACE(@TotalPaidDays,'))',')')
	END   


	SET @index = charindex('(DL ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @TotalDL = REPLACE(@TempCondition,'(DL in ','')
		set @TotalDL = REPLACE(@TotalDL,',',' OR ')
		set @TotalDL = REPLACE(@TotalDL,'))',')')
	END    

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1

END
	
DECLARE @ListLeaveDayCode varchar(max);
DECLARE @ListNoPaidLeaveDayCode varchar(max);
DECLARE @ListPaidLeaveDayCode varchar(max);
DECLARE @ListBusinessTravelCode varchar(max);
DECLARE @ListUsualAllowanceCode varchar(max);

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

select  @ListUsualAllowanceCode = coalesce(@ListUsualAllowanceCode + ',', '') + quotename(Code)
from    Cat_UsualAllowance
where   IsDelete is null
ORDER BY Code;


--lay @DateStart, @DateEnd

DECLARE @DateStart date = (select top 1 DateStart from Att_CutOffDuration WHERE IsDelete is NULL AND MonthYear = @MonthYear );
DECLARE @DateEnd date = (select top 1 DateEnd from Att_CutOffDuration WHERE IsDelete is NULL AND MonthYear = @MonthYear );

  


IF(@CheckData is not null and @CheckData != '')
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
IF (@EmStatus is not null and @EmStatus != '')
BEGIN
	SET @index = charindex('E_PROFILE_NEW',@EmStatus,0) 
	IF(@index > 0)
	BEGIN
		SET @EmStatus = REPLACE(@EmStatus,'''E_PROFILE_NEW''',' (hp.DateHire <= @DateEnd AND hp.DateHire >= @DateStart ) ')
	END
	SET @index = charindex('E_PROFILE_ACTIVE',@EmStatus,0) 
	IF(@index > 0)
	BEGIN
		SET @EmStatus = REPLACE(@EmStatus,'''E_PROFILE_ACTIVE''','(hp.DateQuit IS NULL OR hp.DateQuit > @DateEnd)')
	END
	SET @index = charindex('E_PROFILE_QUIT',@EmStatus,0)
	IF(@index > 0)
	BEGIN
		SET @EmStatus = REPLACE(@EmStatus,'''E_PROFILE_QUIT''',' (hp.DateQuit <= @DateEnd AND hp.DateQuit >= @DateStart) ')	
	END
END


--- Giá trị TotalPaidDay
IF (@TotalPaidDays is not null and @TotalPaidDays != '')
BEGIN
	SET @index = charindex('E_EqualToZero',@TotalPaidDays,0) 
	IF(@index > 0)
	BEGIN
		SET @TotalPaidDays = REPLACE(@TotalPaidDays,'''E_EqualToZero''','TotalPaidDays = 0')
	END
	SET @index = charindex('E_LessThanZero',@TotalPaidDays,0) 
	IF(@index > 0)
	BEGIN
		SET @TotalPaidDays = REPLACE(@TotalPaidDays,'''E_LessThanZero''','TotalPaidDays < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@TotalPaidDays,0) 
	IF(@index > 0)
	BEGIN
		SET @TotalPaidDays = REPLACE(@TotalPaidDays,'''E_GreaterThanZero''','TotalPaidDays > 0')	
	END
END


--- Giá trị DL
IF (@TotalDL is not null and @TotalDL != '')
BEGIN
	SET @index = charindex('E_EqualToZero',@TotalDL,0) 
	IF(@index > 0)
	BEGIN
		SET @TotalDL = REPLACE(@TotalDL,'''E_EqualToZero''','DL = 0')
	END
	SET @index = charindex('E_LessThanZero',@TotalDL,0) 
	IF(@index > 0)
	BEGIN
		SET @TotalDL = REPLACE(@TotalDL,'''E_LessThanZero''','DL < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@TotalDL,0) 
	IF(@index > 0)
	BEGIN
		SET @TotalDL = REPLACE(@TotalDL,'''E_GreaterThanZero''','DL > 0')	
	END
END

Set @ListLeaveDayCode = ISNULL(@ListLeaveDayCode,'')
Set @ListNoPaidLeaveDayCode = ISNULL(@ListNoPaidLeaveDayCode,'')
Set @ListPaidLeaveDayCode = ISNULL(@ListPaidLeaveDayCode,'')
Set @ListBusinessTravelCode = ISNULL(@ListBusinessTravelCode,'')
Set @ListUsualAllowanceCode = ISNULL(@ListUsualAllowanceCode,'')

DECLARE @Query nvarchar(max);
DECLARE @Query2 varchar(max);

-- Query chinh

set @Query = '	
DECLARE @MonthYear date = ''' + @MonthYear + '''
--- Lay ngay bat dau va ket thuc ky luong
DECLARE @DateStart DATE, @DateEnd DATE, @StartMonth  DATE
SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL AND MonthYear = '''+@MonthYear+'''


--DECLARE @MinBaseSalary float
--DECLARE @MinRegionSalary float

--SELECT @MinBaseSalary = Value
--FROM Cat_ValueEntity
--WHERE Type = ''E_MINIMUM_SALARY'' AND DateOfEffect < @DateEnd
--		AND IsDelete IS NULL
--ORDER BY DateUpdate DESC

--SELECT @MinRegionSalary = MinSalary
--FROM Cat_RegionDetail
--WHERE IsDelete IS NULL
--ORDER BY DateUpdate desc

-- Ham phan quyen
if object_id(''tempdb..#tblPermission'') is not null
   drop table #tblPermission;

CREATE TABLE #tblPermission (id uniqueidentifier primary key )
INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'
print (''#tblPermission'');

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

--- bang master data
if object_id(''tempdb..#TbWorkHistory'') is not null 
	drop table #TbWorkHistory;

select		' +@Top+ ' 
			hwh.ProfileID , hp.CodeEmp, hp.ProfileName, cou.E_BRANCH AS DivisionName ,cou.E_UNIT AS CenterName,cou.E_DIVISION AS DepartmentName,cou.E_DEPARTMENT AS SectionName,cou.E_TEAM AS UnitName
			,csc.SalaryClassName,cp.PositionName,cj.JobTitleName,cetl.VN AS EmploymentType,cetl2.VN AS LaborType,cne.NameEntityName AS EmployeeGroupName, cwp.WorkPlaceName
			,hp.DateHire,hp.DateEndProbation,hp.DateQuit
			, @MonthYear as "MonthYear"
			,ag.GradeAttendanceID 
INTO		#TbWorkHistory
FROM		#Hre_WorkHistory as hwh
INNER JOIN	hre_profile hp on hp.Id = hwh.ProfileID
LEFT JOIN	Cat_OrgStructure as cos on cos.ID = hwh.OrganizationStructureID
LEFT JOIN	Cat_OrgUnit as cou on cou.OrgstructureID = hwh.OrganizationStructureID
LEFT JOIN	Cat_SalaryClass as csc on csc.ID = hwh.SalaryClassID
LEFT JOIN	Cat_JobTitle as cj on cj.ID = hwh.JobTitleID
LEFT JOIN	Cat_Position cp on cp.ID = hwh.PositionID
LEFT JOIN	Cat_WorkPlace cwp on cwp.ID = hwh.WorkPlaceID
LEFT JOIN	Cat_NameEntity cne on cne.ID = hwh.EmployeeGroupID
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
			ORDER BY ag.DateUpdate DESC
			) ag

WHERE		hp.IsDelete is null
	AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart)
	AND		hp.DateHire <= @DateEnd
	AND		exists (Select * from #tblPermission tpm where id = hp.id )
			' +ISNULL(@Condition,'')+ '
			' +ISNULL(@EmStatus,'')+ '

print(''#TbWorkHistory'');
'
set @Query2 = '
-- Lay du lieu bang tong hop cong
if object_id(''tempdb..#TbWorkday '') is not null 
	drop table #TbWorkday;
select	' +@Top+ '
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

									when lde.DateEnd = aw.WorkDate AND ( lde.DurationType = ''E_FIRST'' OR lde.DurationType = ''E_FIRST_AND_LAST'' )
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
				ORDER BY ag.DateUpdate DESC
				) ag
		LEFT JOIn	Cat_GradeAttendance cga
			ON		cga.ID = ag.GradeAttendanceID

where   aw.IsDelete is null
        and aw.WorkDate between @DateStart and @DateEnd
        and exists ( select * from   #TbWorkHistory as twh where  twh.ProfileID = aw.ProfileID );
print (''#TbWorkday'');


--Sum phu cap theo che do
SELECT * 
INTO #Sal_BasicSalary 
FROM 
( SELECT *, ROW_NUMBER() OVER (PARTITION BY ProfileID ORDER BY DateOfEffect desc ) AS rk FROM Sal_BasicSalary WHERE DateOfEffect <= @dateEnd AND IsDelete IS NULL ) A
WHERE A.rk = 1 AND ProfileID IN ( SELECT ProfileID FROM #TbWorkHistory )

SELECT B.ProfileID AS ProfileID_alp, CAST(GrossAmount as float) AS GrossAmount, CAST(AdvanceAmount as float) AS AdvanceAmount ,CAST(InsuranceAmount as float) AS InsuranceAmount, cua.Code, B.AllowanceAmount
INTO #Allowance
FROM 
(
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceType1ID AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount1) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION ALL
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceType2ID AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount2) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION all
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceType3ID AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount3) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION ALL
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceType4ID AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount4) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION ALL
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceTypeID5 AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount5) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION all
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceTypeID6 AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount6) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION ALL
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceTypeID7 AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount7) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION all
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceTypeID8 AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount8) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION ALL
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceTypeID9 AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount9) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION all
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceTypeID10 AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount10) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION ALL
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceTypeID11 AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount11) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION all
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceTypeID12 AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount12) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION all
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceTypeID13 AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount13) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION all
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceTypeID14 AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount14) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
UNION ALL
SELECT ProfileID ,dbo.VnrDecrypt(E_GrossAmount) AS GrossAmount,dbo.VnrDecrypt(E_AdvanceSalary) AS AdvanceAmount,dbo.VnrDecrypt(E_InsuranceAmount) AS InsuranceAmount, AllowanceTypeID15 AS AllowanceTypeID, cast(dbo.VnrDecrypt(E_AllowanceAmount15) as float) AS AllowanceAmount FROM #Sal_BasicSalary 
) B
LEFT JOIN Cat_UsualAllowance cua
	ON B.AllowanceTypeID = cua.ID


SELECT * 
INTO #AllowancePivot
FROM #Allowance 
PIVOT ( SUM(AllowanceAmount) FOR Code IN ('+@ListUsualAllowanceCode+') ) AS D
--select * from #AllowanceTemp



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
					--AND tw.DataType = ''E_VALID''
					AND tw.ShiftID IS NOT NULL AND (tw.DataType = ''E_VALID'' OR tw.DataType IS NULL )
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
					--AND tw.DataType = ''E_VALID''
					AND ( tw.ShiftID IS NOT NULL OR tw.LeaveCode1 =''H'') AND (tw.DataType = ''E_VALID'' OR tw.DataType IS NULL)
        ) as Data pivot ( sum(LeaveDays) for LeaveCode in (' + @ListLeaveDayCode + ') ) as pv;
print (''#TbSumLeaveDay'');


-- Sum  ngay lam viec
if object_id(''tempdb..#TbSumWorkDay'') is not null
   drop table #TbSumWorkDay;
select  tw.ProfileID AS ProfileID_tswd
      , sum(tw.WorkDays) as TotalWorkDays
into    #TbSumWorkDay
from    #TbWorkday as tw
group by tw.ProfileID;
print (''#TbSumWorkDay'');


--- Dem so nguoi phu thuoc
if object_id(''tempdb..#CountDependant'') is not null
   drop table #CountDependant;

SELECT		ProfileID, COUNT(*) AS CountDependant
INTO		#CountDependant
FROM		Hre_Dependant 
WHERE		IsDelete IS NULL AND MonthOfEffect < @DateEnd AND ( MonthOfExpiry IS NULL OR MonthOfExpiry > @DateStart )
GROUP BY	ProfileID


-- Bang ket qua tong
;WITH Results AS
(
select	twh.*,alp.*
		,CASE WHEN dbo.fnc_NumberOfExceptWeekends(@DateStart,@DateEnd) >= 22 THEN 22 else dbo.fnc_NumberOfExceptWeekends(@DateStart,@DateEnd) END AS StdWorkDayCount
		,isnull(tswd.TotalWorkDays,0) + isnull(tsbl.TotalBusinessTravelDays,0) + isnull([WFH],0) AS WorkDayCount
		,ISNULL(tsld.H,0) AS H, ISNULL(tsld.AN,0) AS AN, ISNULL(tsld.TotalPaidLeaveDay,0) - ISNULL(tsld.AN,0) AS TotalPaidLeaveDay, ISNULL(tsld.DL,0) AS DL, ISNULL(tsld.TotalNoPaidLeaveDay,0) AS TotalNoPaidLeaveDay
		,isnull(tsld.TotalPaidLeaveDay,0) + isnull(tsld.H,0) + isnull(tswd.TotalWorkDays,0) + isnull(tsbl.TotalBusinessTravelDays,0) + isnull([WFH],0) as TotalPaidDays
		,cdp.CountDependant
		,sup.Amount AS AdvanceSalary
		,cve.Value AS MinBaseSalary
		,crd.MinSalary AS MinRegionSalary
		,cri.SocialInsCompRate,cri.HealthInsCompRate,cri.UnemployInsCompRate,cri.SocialInsEmpRate,cri.HealthInsEmpRate,cri.UnemployInsEmpRate,cri.HealthInsTotalRate
		,cpf.DependentDeduction
		,cpf.PersonalDeduction
		,@DateStart AS DateStart
		,@DateEnd AS DateEnd
		,GETDATE() AS DateExport
	  	,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "hwh.EmploymentType",NULL AS "hwh.SalaryClassID" ,NULL AS "hwh.PositionID", NULL AS "hwh.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit"
		,NULL AS "hwh.WorkPlaceID",NULL AS "hwh.EmployeeGroupID", NULL AS "hwh.LaborType"
		,NULL AS "EmpStatus",NULL AS "CheckData"
		,NULL AS "IsAdvance"
		,Agr.ProfileID AS AgrProfileID
		,ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as RowNumber
from    #TbWorkHistory as twh
        left join #TbSumBusinessLeave as tsbl on tsbl.ProfileID_tsbl = twh.ProfileID
        left join #TbSumLeaveDay as tsld on tsld.ProfileID_tsld = twh.ProfileID
        left join #TbSumWorkDay as tswd on tswd.ProfileID_tswd = twh.ProfileID
		--left join #TbSumWorkDay as tswd2 on tswd2.ProfileID_tswd = twh.ProfileID
		left join #AllowancePivot alp on alp.ProfileID_alp = twh.ProfileID
		left join #CountDependant cdp on cdp.ProfileID = twh.ProfileID
		left join Sal_UnusualPay sup on sup.ProfileID = twh.ProfileID AND sup.MonthYear = @MonthYear AND sup.IsDelete IS NULL
		OUTER APPLY ( SELECT TOP (1) agr.ProfileID FROM att_grade agr where agr.ProfileID = twh.ProfileID AND agr.MonthStart < @DateEnd AND agr.isdelete IS null ORDER BY agr.MonthStart DESC ) Agr
		OUTER APPLY ( 
					SELECT TOP(1) SocialInsCompRate,HealthInsCompRate,UnemployInsCompRate,SocialInsEmpRate,HealthInsEmpRate,UnemployInsEmpRate,HealthInsCompRate + HealthInsEmpRate AS HealthInsTotalRate  FROM Cat_RateInsurance 
					WHERE IsDelete IS NULL AND ApplyFrom <= @DateEnd
					ORDER BY DateUpdate DESC 
					) cri
		OUTER APPLY ( SELECT TOP(1) Value FROM Cat_ValueEntity WHERE IsDelete IS NULL AND Type = ''E_MINIMUM_SALARY'' AND DateOfEffect <= @DateEnd ORDER BY DateUpdate ) cve
		OUTER APPLY ( SELECT TOP(1) MinSalary FROM Cat_RegionDetail WHERE IsDelete IS NULL AND DateOfEffect <= @DateEnd ORDER BY DateUpdate desc ) crd
		OUTER APPLY ( SELECT TOP(1) PersonalDeduction,DependentDeduction FROM Cat_PITFormula WHERE IsDelete IS NULL AND Type = ''E_PROGRESSIVE'' AND EffectiveMonth <= @DateEnd ORDER BY DateUpdate DESC ) cpf

)
select * 
INTO	#Results
from	Results
where	1= 1 '+@TotalPaidDays+' '+@GradeAttendance+' '+@CheckData+' '+@TotalDL+'


Select	RowNumber as STT, *
from	#Results
ORDER	BY RowNumber

drop table #tblPermission, #TbSumBusinessLeave,#Sal_BasicSalary,#Allowance,#AllowancePivot, #TbSumLeaveDay, #TbSumWorkDay, #TbWorkday, #TbWorkHistory, #Results;

';
			
            exec (@Query + @Query2);
   --         set @Query = replace(replace(@Query, char(13) + char(10), char(10)), char(13), char(10));
   --         while len(@Query) > 1
   --               begin
   --                     if charindex(char(10), @Query) between 1 and 4000
   --                        begin
   --                              set @CurrentEnd = charindex(char(10), @Query) - 1;
   --                              set @Offset = 2;
   --                        end;
   --                     else
   --                        begin
   --                              set @CurrentEnd = 4000;
   --                              set @Offset = 1;
   --                        end;   
   --                     print substring(@Query, 1, @CurrentEnd); 
   --                     set @Query = substring(@Query, @CurrentEnd + @Offset, len(@Query));   
   --               end;


			--set @Query2 = replace(replace(@Query2, char(13) + char(10), char(10)), char(13), char(10));
   --         while len(@Query2) > 1
   --               begin
   --                     if charindex(char(10), @Query2) between 1 and 4000
   --                        begin
   --                              set @CurrentEnd = charindex(char(10), @Query2) - 1;
   --                              set @Offset = 2;
   --                        end;
   --                     else
   --                        begin
   --                              set @CurrentEnd = 4000;
   --                              set @Offset = 1;
   --                        end;   
   --                     print substring(@Query2, 1, @CurrentEnd); 
   --                     set @Query2 = substring(@Query2, @CurrentEnd + @Offset, len(@Query2));   
   --               end;

        --rpt_TempBasicSalary
      end;
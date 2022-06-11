
ALTER proc dr_BCCongChiTietThang
@Condition varchar(max) = " and (MonthYear = ''2021/10/01'') "
--@Condition varchar(max) = N' and (MonthYear = ''2021/09/01'') and (Cos.OrderNumber is not null) '
, @Username varchar(100) = 'khang.nguyen'
, @PageIndex int = 1
, @PageSize int = 20
AS
begin
    set nocount on;
    declare @Query varchar(max);
	declare @Query2 varchar(max);
    declare @Top varchar(20) = ' ';
    declare @CurrentEnd bigint;
    declare @Offset tinyint;

-- Tach dieu kien
    declare @TempID varchar(max);
    declare @TempCondition varchar(max);
    declare @MonthYearCondition varchar(max);
    declare @MonthYear varchar(20) = '';
    set @TempCondition = replace(@Condition, ',', '@');
    set @TempCondition = replace(@TempCondition, 'and (', ',');
    declare @Count int = 1;
    declare @ListCol varchar(max);
    declare @ListAlilas varchar(max);
    declare @ListShiftCode varchar(max);
    declare @ListOverTimeType varchar(max);
    declare @ListLeaveDayCode varchar(max);
    declare @ListNoPaidLeaveDayCode varchar(max);
    declare @ListPaidLeaveDayCode varchar(max);
    declare @ListBusinessTravelCode varchar(max);
			
	DECLARE @str nvarchar(max)
	declare @countrow int
	declare @row int
	declare @index int
	declare @ID nvarchar(500)
	set @str = REPLACE(@condition,',','@')
	set @str = REPLACE(@str,'and (',',')
	SELECT ID into #tableTempCondition FROM SPLIT_To_NVARCHAR (@str)
	set @row = (SELECT count(ID) FROM SPLIT_To_NVARCHAR (@str))
	set @countrow = 0
	set @index = 0
	DECLARE @tempCodition nvarchar(Max)
	DECLARE @NotHaveData NVARCHAR(500) =' '
	DECLARE @IstHaveData NVARCHAR(500) =' '
	DECLARE @CheckData NVARCHAR(500) =' '
	DECLARE @EmStatus NVARCHAR(500) = ' '
	DECLARE @GradeAttendance NVARCHAR(max) = '' 
	DECLARE @TotalPaidDays NVARCHAR(max) = '' 
	DECLARE @IsAdvance NVARCHAR(100) =''

	WHILE @row > 0
	BEGIN
		set @index = 0
		set @ID = (select top 1 ID from #tableTempCondition)
		set @tempID = replace(@ID,'@',',')
		

		set @index = charindex('(ProfileName ','('+@tempID,0) 
		if(@index > 0)
		begin
     		SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
		END

		set @index = charindex('CheckData ',@tempID,0)
		if(@index > 0)
		BEGIN
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @CheckData = REPLACE(@tempCodition,'CheckData','')
			set @CheckData = REPLACE(@CheckData,'like N','')
			set @CheckData = REPLACE(@CheckData,'%','')
		END

		set @index = charindex('(EmpStatus ','('+@tempID,0) 
		if(@index > 0)
		BEGIN
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @EmStatus = REPLACE(@tempCodition,'(EmpStatus IN ','')
			set @EmStatus = REPLACE(@EmStatus,',',' OR ')
			set @EmStatus = REPLACE(@EmStatus,'))',')')
		END

		set @index = charindex('(GradeAttendanceID ','('+@tempID,0) 
		if(@index > 0)
		BEGIN
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @GradeAttendance = @tempCodition

		END

		set @index = charindex('(TotalPaidDays ','('+@tempID,0) 
		if(@index > 0)
		BEGIN
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @TotalPaidDays = @tempCodition
		END

		set @index = charindex('(IsAdvance ','('+@tempID,0) 
		if(@index > 0)
		BEGIN
			set @tempCodition = 'and ('+@tempID
			set @condition = REPLACE(@condition,@tempCodition,'')
			set @IsAdvance = REPLACE(@tempCodition,' ','') 
		END


		DELETE #tableTempCondition WHERE ID = @ID
		set @row = @row - 1

	END

	SET @TempID =''


    if ltrim(rtrim(@Condition)) = ''
        or @Condition is null
        begin
                set @Top = ' top 0 ';
                set @MonthYear = dateadd(day, -day(getdate()) + 1, convert(date, getdate()));
        end;

    select  id
    into    #SplitCondition
    from    SPLIT_To_VARCHAR(@TempCondition);

    while (select   count(*)
            from     #SplitCondition
            ) > 0
            begin
                set @TempID = (select top 1
                                        id
                                from     #SplitCondition
                                );
-- Dieu kien @MonthYearCondition
                if (select  patindex('%MonthYear%', @TempID)
                    ) > 0
                    begin
                            set @TempCondition = ltrim(rtrim(@TempID));
                            set @MonthYearCondition = replace(@TempCondition, '', '');
                            set @MonthYearCondition = ('and (' + replace(@MonthYearCondition, '@', ','));
                            set @MonthYear = substring(@MonthYearCondition, patindex('%[0-9]%', @MonthYearCondition), 10);
                            set @Condition = replace(@Condition, @MonthYearCondition, '');
                    end;
                delete  #SplitCondition
                where   id = @TempID;
            end;
    drop table #SplitCondition;

        select  @ListShiftCode = coalesce(@ListShiftCode + ',', '') + quotename(Code)
		FROM	Cat_Shift
		where   IsDelete is NULL
		ORDER BY Code
		;

        select  @ListOverTimeType = coalesce(@ListOverTimeType + ',', '') + quotename(Code)
        from    Cat_OvertimeType
        where   IsDelete is NULL
		ORDER BY Code;

        select  @ListLeaveDayCode = coalesce(@ListLeaveDayCode + ',', '') + quotename(Code)
        from    Cat_LeaveDayType
        where   IsDelete is NULL
		ORDER BY Code;

        select  @ListPaidLeaveDayCode = coalesce(@ListPaidLeaveDayCode + ',', '') + quotename(Code)
        from    Cat_LeaveDayType
        where   IsDelete is null
                and PaidRate = 1
                and Code not in ('HLD')
		ORDER BY Code;

        select  @ListNoPaidLeaveDayCode = coalesce(@ListNoPaidLeaveDayCode + ',', '') + quotename(Code)
        from    Cat_LeaveDayType
        where   IsDelete is null
                and (
                        PaidRate = 0
        or PaidRate is null
                    )
                and Code not in ('DL')
				
		ORDER BY Code;

        select  @ListBusinessTravelCode = coalesce(@ListBusinessTravelCode + ',', '') + quotename(BusinessTravelCode)
        from    Cat_BusinessTravel
        where   IsDelete is NULL
		ORDER BY BusinessTravelCode;


	--lay @DateStart, @DateEnd

    declare @DateStart date = (select top 1
                                        DateStart
                                from     Att_CutOffDuration
                                where    IsDelete is null
                                        and MonthYear = @MonthYear
                                );
    declare @DateEnd date = (select top 1
                                    DateEnd
                                from   Att_CutOffDuration
                                where  IsDelete is null
                                    and MonthYear = @MonthYear
                            );

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

-----Đk Ngay cong tra luong
IF(@TotalPaidDays is not null and @TotalPaidDays != '')
BEGIN
SELECT @TotalPaidDays = ' AND ProfileID IN ( SELECT ProfileID From Results WHERE 1 = 1 ' + @TotalPaidDays + ')'
END

----Co che do cong
IF(@GradeAttendance is not null and @GradeAttendance != '')
BEGIN
SELECT @GradeAttendance = ' AND ProfileID IN ( SELECT ProfileID From Results WHERE 1 = 1 ' + @GradeAttendance + ')'
END

--SELECT @Condition, @CheckData
-- Query chinh

set @Query = '	
declare @MonthYear date = ''' + @MonthYear + '''
declare @DateStart date = ''' + convert(varchar(20), @DateStart, 111) + ''';
declare @DateEnd date = ''' + convert(varchar(20), @DateEnd, 111) + ''';


-- Ham phan quyen
if object_id(''tempdb..#tblPermission'') is not null
   drop table #tblPermission;

CREATE TABLE #tblPermission (id uniqueidentifier primary key )
INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'
print (''#tblPermission'');

-- Lay du lieu qtct moi nhat trong thang
if object_id(''tempdb..#TbWorkHistory'') is not null 
	drop table #TbWorkHistory;

;WITH WorkHistory AS
(
select		hwh.ProfileID , hp.CodeEmp, hp.ProfileName, cou.E_BRANCH AS DivisionName ,cou.E_UNIT AS CenterName,cou.E_DIVISION AS DepartmentName,cou.E_DEPARTMENT AS SectionName,cou.E_TEAM AS UnitName
			,csc.SalaryClassName,cp.PositionName,cj.JobTitleName,cetl.VN AS EmploymentType,cetl2.VN AS LaborType,cne.NameEntityName AS EmployeeGroupName, cwp.WorkPlaceName
			,hp.DateHire,hp.DateEndProbation,hp.DateQuit
			, @MonthYear as "MonthYear"
			,ROW_NUMBER() OVER(PARTITION BY hwh.ProfileID ORDER BY hwh.DateEffective DESC) AS rk
			,ag.GradeAttendanceID 
from		Hre_WorkHistory as hwh
left join	hre_profile hp on hp.Id = hwh.ProfileID
left join	Cat_OrgStructure as cos on cos.ID = hwh.OrganizationStructureID
left join	Cat_OrgUnit as cou on cou.OrgstructureID = hwh.OrganizationStructureID
left join	Cat_SalaryClass as csc on csc.ID = hwh.SalaryClassID
left join	Cat_JobTitle as cj on cj.ID = hwh.JobTitleID
left join	Cat_Position cp on cp.ID = hwh.PositionID
left join	Cat_WorkPlace cwp on cwp.ID = hwh.WorkPlaceID
left join	Cat_NameEntity cne on cne.ID = hwh.EmployeeGroupID
inner join	#tblPermission tp on tp.ID = hwh.ProfileID
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
WHERE		hwh.IsDelete is null
	AND		hwh.DateEffective <= @DateEnd
	AND		hwh.Status = ''E_APPROVED''
	AND		hp.IsDelete is null
	AND		( hp.DateQuit IS NULL OR hp.DateQuit > @DateStart)
	AND		hp.DateHire <= @DateEnd
			' + @Condition + '
			'+ISNULL(@EmStatus,'')+'
) 

SELECT	*
INTO	#TbWorkHistory
FROM	WorkHistory 
WHERE	rk = 1
print(''#TbWorkHistory'');


-- Lay du lieu bang tong hop cong
if object_id(''tempdb..#TbWorkday '') is not null 
	drop table #TbWorkday;
select ' + @Top
                + '
		aw.ID
		,aw.ProfileID
		,aw.WorkDate
		,cs.ShiftCode
		,CASE WHEN cs.ShiftCode = ''2'' AND 1 - (ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0)) >= 0.5 AND LeaveDays3 IS NULL then 0.5 
		WHEN cs.ShiftCode = ''3'' AND 1 - (ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0)) = 1 then 7.5
		WHEN cs.ShiftCode = ''3'' AND 1 - (ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0)) = 0.5 AND LeaveDays2 IS NULL then 4.0
		WHEN cs.ShiftCode = ''3'' AND 1 - (ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0)) = 0.5 AND LeaveDays3 IS NULL then 3.5
		END AS NS1
		,CASE WHEN ISNULL(LEAVEDETAIL.LeaveDays1,0) = 1 THEN 0
			WHEN ISNULL(BUSINESSDETAIL.BusinessDay1,0) = 1 THEN 1 - ( ISNULL(LEAVEDETAIL.LeaveDays1,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0) )
			WHEN ISNULL(BUSINESSDETAIL.BusinessDay1,0) = 0 AND ISNULL(LEAVEDETAIL.LeaveDays1,0) = 0 THEN
				CASE WHEN ISNULL(BUSINESSDETAIL.BusinessDay2,0) - ISNULL(LEAVEDETAIL.LeaveDays2,0) > 0 THEN  ISNULL(BUSINESSDETAIL.BusinessDay2,0) - ISNULL(LEAVEDETAIL.LeaveDays2,0) ELSE 0 END
				+ CASE WHEN  ISNULL(BUSINESSDETAIL.BusinessDay3,0) - ISNULL(LEAVEDETAIL.LeaveDays3,0) > 0 THEN ISNULL(BUSINESSDETAIL.BusinessDay3,0) - ISNULL(LEAVEDETAIL.LeaveDays3,0) ELSE 0 END
		END AS BusinessDay
		,CASE WHEN cs.ShiftCode is not null THEN 
			CASE WHEN ISNULL(LEAVEDETAIL.LeaveDays1,0) = 1 THEN 0
				WHEN ISNULL(BUSINESSDETAIL.BusinessDay1,0) = 1 THEN 0
				WHEN ISNULL(BUSINESSDETAIL.BusinessDay1,0) = 0 AND ISNULL(LEAVEDETAIL.LeaveDays1,0) = 0 THEN
					CASE WHEN 0.5 - ( ISNULL(BUSINESSDETAIL.BusinessDay2,0) + ISNULL(LEAVEDETAIL.LeaveDays2,0) ) > 0 THEN 0.5 ELSE 0 END 
					+ CASE WHEN 0.5 - ( ISNULL(BUSINESSDETAIL.BusinessDay3,0) + ISNULL(LEAVEDETAIL.LeaveDays3,0) ) > 0 THEN 0.5 ELSE 0 END 
			END
		END AS WorkDays
		,CASE WHEN aw.DataType = ''E_INVALID'' THEN ''???''
		ELSE
			--CASE WHEN cs.ShiftCode IS NOT NULL THEN
				CASE WHEN LEAVEDETAIL.LeaveCode1 is not null 
					THEN LEAVEDETAIL.LeaveCode1

					WHEN LEAVEDETAIL.LeaveCode2 is not NULL AND LEAVEDETAIL.LeaveCode3 is NULL
					THEN concat( LEAVEDETAIL.LeaveDays2, LEAVEDETAIL.LeaveCode2, '' | '', 1 - LEAVEDETAIL.LeaveDays2 , COALESCE(BUSINESSDETAIL.BusinessCode1,BUSINESSDETAIL.BusinessCode3,''Ca'' + cs.ShiftCode ))

					when LEAVEDETAIL.LeaveCode2 is NULL AND LEAVEDETAIL.LeaveCode3 is not null
					then concat(1 - LEAVEDETAIL.LeaveDays3 , COALESCE(BUSINESSDETAIL.BusinessCode1,BUSINESSDETAIL.BusinessCode2,''Ca'' + cs.ShiftCode ),  '' | '',LEAVEDETAIL.LeaveDays3, LEAVEDETAIL.LeaveCode3 )

					when LEAVEDETAIL.LeaveCode2 is not null and LEAVEDETAIL.LeaveCode3 is not null
					then concat( LEAVEDETAIL.LeaveDays2 ,LEAVEDETAIL.LeaveCode2, '' | '',LEAVEDETAIL.LeaveDays3 , LEAVEDETAIL.LeaveCode3)

					WHEN BUSINESSDETAIL.BusinessCode1 IS NOT NULL 
					THEN BUSINESSDETAIL.BusinessCode1

					WHEN BUSINESSDETAIL.BusinessCode2 IS NOT NULL AND BUSINESSDETAIL.BusinessCode3 IS NULL
					THEN concat( BUSINESSDETAIL.BusinessDay2, BUSINESSDETAIL.BusinessCode2, '' | '', 1 - BUSINESSDETAIL.BusinessDay2 , COALESCE(BUSINESSDETAIL.BusinessCode3,''Ca''+ cs.ShiftCode ))

					WHEN BUSINESSDETAIL.BusinessCode2 IS NULL AND BUSINESSDETAIL.BusinessCode3 IS NOT NULL
					THEN concat(1 - BUSINESSDETAIL.BusinessDay3 , COALESCE(BUSINESSDETAIL.BusinessCode2,''Ca'' + cs.ShiftCode ),  '' | '', BUSINESSDETAIL.BusinessDay3, BUSINESSDETAIL.BusinessCode3 )
					ELSE ''Ca''+ cs.ShiftCode
				END
			--END
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
					order by DateUpdate desc
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
					order by DateUpdate 
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
					order by DateUpdate desc
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
					order by DateUpdate 
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
								OR ld1.DurationType = ''E_FIRST'' or lde.DurationType = ''E_FIRST'' 
								OR ld1.DurationType = ''E_FIRST_AND_LAST'' or lde.DurationType = ''E_FIRST_AND_LAST''
								THEN
								CASE WHEN ld1.DateStart = aw.WorkDate AND ( ld1.DurationType = ''E_FIRSTHALFSHIFT'' OR ld1.DurationType = ''E_FIRST'' OR ld1.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(ld1.DurationType, ''-'',''0.5'', ''-'', ld1.LeaveDayTypeCode)

									when lde.DateStart = aw.WorkDate AND ( lde.DurationType = ''E_FIRSTHALFSHIFT'' OR lde.DurationType = ''E_FIRST'' OR lde.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(lde.DurationType, ''-'', ''0.5'', ''-'', lde.LeaveDayTypeCode)
								END
                            end as FirstShift_L

                          , case when ld1.DurationType = ''E_LASTHALFSHIFT'' or lde.DurationType = ''E_LASTHALFSHIFT'' 
								OR ld1.DurationType = ''E_LAST'' or lde.DurationType = ''E_LAST'' 
								OR ld1.DurationType = ''E_FIRST_AND_LAST'' or lde.DurationType = ''E_FIRST_AND_LAST''
								THEN
								CASE WHEN	ld1.DateEnd = aw.WorkDate AND ( ld1.DurationType = ''E_LASTHALFSHIFT'' OR ld1.DurationType = ''E_LAST'' OR ld1.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(ld1.DurationType, ''-'', ld1.LeaveDays, ''-'', ld1.LeaveDayTypeCode)

									when lde.DateEnd = aw.WorkDate AND ( lde.DurationType = ''E_LASTHALFSHIFT'' OR lde.DurationType = ''E_LAST'' OR lde.DurationType = ''E_FIRST_AND_LAST'' )
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
								OR tbt1.DurationType = ''E_FIRST'' or tbt2.DurationType = ''E_FIRST''
								OR tbt1.DurationType = ''E_FIRST_AND_LAST'' or tbt2.DurationType = ''E_FIRST_AND_LAST''
								THEN
								CASE WHEN	
									tbt1.DateFrom = aw.WorkDate AND ( tbt1.DurationType = ''E_FIRSTHALFSHIFT'' OR tbt1.DurationType = ''E_FIRST'' OR tbt1.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(tbt1.DurationType, ''-'', ''0.5'', ''-'', tbt1.BusinessTravelCode)

									when tbt2.DateFrom = aw.WorkDate AND ( tbt2.DurationType = ''E_FIRSTHALFSHIFT'' OR tbt2.DurationType = ''E_FIRST'' OR tbt2.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(tbt2.DurationType, ''-'', ''0.5'', ''-'', tbt2.BusinessTravelCode)
								END

                            end as FirstShift_B
                          , case when tbt1.DurationType = ''E_LASTHALFSHIFT'' or tbt2.DurationType = ''E_LASTHALFSHIFT''
								OR tbt1.DurationType = ''E_LAST'' or tbt2.DurationType = ''E_LAST''
								OR tbt1.DurationType = ''E_FIRST_AND_LAST'' or tbt2.DurationType = ''E_FIRST_AND_LAST''
								THEN
								CASE WHEN	
									tbt1.DateTo = aw.WorkDate AND ( tbt1.DurationType = ''E_LASTHALFSHIFT'' OR tbt1.DurationType = ''E_LAST'' OR tbt1.DurationType = ''E_FIRST_AND_LAST'' )
									then concat(tbt1.DurationType, ''-'', ''0.5'', ''-'', tbt1.BusinessTravelCode)

									when tbt2.DateTo = aw.WorkDate AND ( tbt2.DurationType = ''E_LASTHALFSHIFT'' OR tbt2.DurationType = ''E_LAST'' OR tbt2.DurationType = ''E_FIRST_AND_LAST'' )
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
						  , left(LEAVE.StringLeaveCode2, charindex(''-'', LEAVE.StringLeaveCode3) - 1) as DurationType3
                          , right(LEAVE.StringLeaveCode1, charindex(''-'', reverse(LEAVE.StringLeaveCode1)) - 1) as LeaveCode1
                          , right(LEAVE.StringLeaveCode2, charindex(''-'', reverse(LEAVE.StringLeaveCode2)) - 1) as LeaveCode2
						  , right(LEAVE.StringLeaveCode3, charindex(''-'', reverse(LEAVE.StringLeaveCode3)) - 1) as LeaveCode3
                          , case when left(LEAVE.StringLeaveCode1, charindex(''-'', LEAVE.StringLeaveCode1) - 1) = ''E_FULLSHIFT'' then 1
							end as LeaveDays1
                          , case when left(LEAVE.StringLeaveCode2, charindex(''-'', LEAVE.StringLeaveCode2) - 1) IN (''E_FIRSTHALFSHIFT'',''E_FIRST'',''E_FIRST_AND_LAST'' ) then 0.5
							end as LeaveDays2
						  , case when left(LEAVE.StringLeaveCode3, charindex(''-'', LEAVE.StringLeaveCode3) - 1) IN ( ''E_LASTHALFSHIFT'',''E_LAST'',''E_FIRST_AND_LAST'' ) then 0.5
							end as LeaveDays3
                    ) LEAVEDETAIL
        cross apply (select left(BUSINESS.StringBusinessCode1, charindex(''-'', BUSINESS.StringBusinessCode1) - 1) as B_DurationType1
                          , left(BUSINESS.StringBusinessCode2, charindex(''-'', BUSINESS.StringBusinessCode2) - 1) as B_DurationType2
						  , left(BUSINESS.StringBusinessCode2, charindex(''-'', BUSINESS.StringBusinessCode3) - 1) as B_DurationType3
                          , right(BUSINESS.StringBusinessCode1, charindex(''-'', reverse(BUSINESS.StringBusinessCode1)) - 1) as BusinessCode1
                          , right(BUSINESS.StringBusinessCode2, charindex(''-'', reverse(BUSINESS.StringBusinessCode2)) - 1) as BusinessCode2
						  , right(BUSINESS.StringBusinessCode3, charindex(''-'', reverse(BUSINESS.StringBusinessCode3)) - 1) as BusinessCode3
                          , case when left(BUSINESS.StringBusinessCode1, charindex(''-'', BUSINESS.StringBusinessCode1) - 1) = ''E_FULLSHIFT'' then 1
							end as BusinessDay1
                          , case when left(BUSINESS.StringBusinessCode2, charindex(''-'', BUSINESS.StringBusinessCode2) - 1) IN (''E_FIRSTHALFSHIFT'',''E_FIRST'',''E_FIRST_AND_LAST'' ) then 0.5
							end as BusinessDay2
						  , case when  left(BUSINESS.StringBusinessCode3, charindex(''-'', BUSINESS.StringBusinessCode3) - 1) IN ( ''E_LASTHALFSHIFT'',''E_LAST'',''E_FIRST_AND_LAST'' ) then 0.5
							end as BusinessDay3
                    ) BUSINESSDETAIL

where   aw.IsDelete is null
        and aw.WorkDate between @DateStart and @DateEnd
        and exists ( select *
                     from   #TbWorkHistory as twh
                     where  twh.ProfileID = aw.ProfileID );
print (''#TbWorkday'');


--Sum du lieu OT theo tung ngay cua moi nv
if object_id(''tempdb..#Att_Overtime_Sum'') is not null
   drop table #Att_Overtime_Sum;

SELECT		ProfileID, WorkDateRoot, Status, SUM(ConfirmHours) AS ConfirmHours_Sum
INTO		#Att_Overtime_Sum
FROM		Att_Overtime
WHERE		WorkDateRoot between @DateStart and @DateEnd
			and Status = ''E_CONFIRM'' AND IsDelete is null
GROUP BY	ProfileID, WorkDateRoot, Status


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
				WHEN tw.LeaveCode1 =''H'' THEN tw.LeaveCode1 + CASE WHEN aos.ConfirmHours_Sum > 0 THEN '' : '' + CONVERT(VARCHAR(10),aos.ConfirmHours_Sum) ELSE '''' END
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
left join (select   ID, Code as OvertimeTypeCode
			from     Cat_OvertimeType
			where    IsDelete is null
           ) as cot on cot.ID = ao.OvertimeTypeID
where   1 =1
        and exists ( select *
                     from   #TbWorkHistory as twh
                     where  twh.ProfileID = tw.ProfileID );
print (''#TbOvertime'');

--select * from #TbOvertime where ProfileID =''3B1BC31F-9996-4EFD-9681-1290B4B0220E''  ORDER BY WorkDateRoot desc

-- Pivot du lieu chi tiet
if object_id(''tempdb..#TbDetail'') is not null
   drop table #TbDetail;
select  *
into    #TbDetail
from    (select pv.ProfileID AS ProfileID_td
              , 1 as OrderNumber
			  , (datediff(dd, @DateStart, @DateEnd) + 1) - (datediff(wk, @DateStart, @DateEnd) * 2) 
			  - (case when datename(dw, @DateStart) = ''Sunday'' then 1 else 0 end) - (case when datename(dw, @DateEnd) = ''Saturday'' then 1 else 0 end) 
			  as "STDWorkingDays"
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
         where  1 = 1
				--AND tw.DataType = ''E_VALID''
				AND (tw.DataType = ''E_VALID'' OR tw.DataType IS NULL )

				
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
		cross apply ( values ( tw.BusinessCode1, convert(float, tw.RealBusinessDay1)), ( tw.BusinessCode2, convert(float, tw.RealBusinessDay2))  , ( tw.BusinessCode3, convert(float, tw.RealBusinessDay3)) ) as BT (BusinessCode, BusinessDay)
		where		BT.BusinessCode in (' + replace(replace(@ListBusinessTravelCode, '[', ''''), ']', '''') + ')
					--AND tw.DataType = ''E_VALID''
					AND (tw.DataType = ''E_VALID'' OR tw.DataType IS NULL )
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
					AND (tw.DataType = ''E_VALID'' OR tw.DataType IS NULL )
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
         where  1 = 1
				--AND tov.DataType = ''E_VALID''
				AND (tov.DataType = ''E_VALID'' OR tov.DataType IS NULL )
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
	  , sum(case when tw.WorkDayStatus = ''E_WAIT_CONFIRMED'' then 1 end) as TotalWDWaitConfirmed
	  , sum(case when tw.WorkDayStatus is null then 1 end) as TotalWDNull
into    #TbSumWorkDay
from    #TbWorkday as tw
group by tw.ProfileID;
print (''#TbSumWorkDay'');

----SumNightShiftHours
if object_id(''tempdb..#SumNightShiftHours'') is not null
   drop table #SumNightShiftHours;
;WITH NightShif AS
(
SELECT	ProfileID
		,CASE WHEN ShiftCode = ''2'' AND WorkDays + BusinessDay  >= 0.5 AND LeaveDays3 IS NULL then 0.5 
		WHEN ShiftCode = ''3'' AND WorkDays + BusinessDay = 1 then 7.5
		WHEN ShiftCode = ''3'' AND WorkDays + BusinessDay = 0.5 AND LeaveDays2 IS NULL then 4.0
		WHEN ShiftCode = ''3'' AND WorkDays + BusinessDay = 0.5 AND LeaveDays3 IS NULL then 3.5
		END AS NS1
FROM	#TbWorkday tw
WHERE	tw.DataType = ''E_VALID'' OR tw.DataType IS NULL
)
SELECT	ProfileID, SUM(NS1) AS NS1
INTO	#SumNightShiftHours
FROM	NightShif
GROUP BY ProfileID

---Count ngay co ca lam viec
if object_id(''tempdb..#TbCountHaveShift'') is not null
   drop table #TbCountHaveShift;

Select	tw.ProfileID,Count(ShiftID) AS CountHaveShift
into    #TbCountHaveShift
from    #TbWorkday as tw
WHERE	ShiftID IS NOT NULL
		--and tw.DataType = ''E_VALID''
		AND (tw.DataType = ''E_VALID'' OR tw.DataType IS NULL )
		
group by tw.ProfileID;
print (''#TbCountHaveShift'');

--select * from #TbWorkday where profileid =''84169C23-DC42-44A2-A216-815E0A04AEA6'' order by workdate

'
set @Query2 = '
-- Bang ket qua tong
;WITH Results AS
(
select  NULL AS STT
		,twh.*, td.*
		, ISNULL(I,0) + ISNULL(I1,0) + ISNULL(I2,0) + ISNULL(I3,0) AS I
		, ISNULL(E,0) AS E
		, ISNULL(G,0) + ISNULL(G1,0) + ISNULL(G2,0) + ISNULL(G3,0) + ISNULL(G4,0) + ISNULL(G5,0) + ISNULL(G6,0) + ISNULL(G7,0) + ISNULL(G8,0) + ISNULL(G9,0) + ISNULL(G10,0) + ISNULL(G11,0) + ISNULL(G12,0) + ISNULL(G13,0) + ISNULL(G14,0) + ISNULL(G15,0) + ISNULL(G16,0) + ISNULL(G17,0)  AS G
		, ISNULL(D,0) AS D, ISNULL([1],0) AS Ca1, ISNULL([2],0) AS Ca2, ISNULL([3],0) AS Ca3, ISNULL(BG,0) AS BG, ISNULL(BU,0) AS BU
		, tsbl.*, tsld.*
		,isnull(tsld.TotalPaidLeaveDay,0) + isnull(tsld.HLD,0) + isnull(tswd.TotalWorkDays,0) + isnull(tsbl.TotalBusinessTravelDays,0) + isnull([WFH],0) as TotalPaidDays
		,isnull(tswd.TotalWorkDays,0) AS RealWorkDayCount
		,ISNULL(tswd.TotalWD,0) - ISNULL(tchs.CountHaveShift,0) AS TotalLeaveDayWeekly
		,tso.*
		,snsh.NS1
		,nullif(isnull(snsh.NS1,0) + ISNULL(tso.NS2,0) + ISNULL(tso.NS3,0) + ISNULL(tso.NS4,0) ,0) as TotalNS
		, tswd.*
		,@DateStart AS DateStart
		,@DateEnd AS DateEnd
		,GETDATE() AS DateExport
	  	,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "hwh.EmploymentType",NULL AS "hwh.SalaryClassID" ,NULL AS "hwh.PositionID", NULL AS "hwh.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "hwh.WorkPlaceID"
		,NULL AS "hwh.EmployeeGroupID", NULL AS "hwh.LaborType"
		,NULL AS "EmpStatus",NULL AS "CheckData"
		,NULL AS "IsAdvance"
		,Agr.ProfileID AS AgrProfileID
		,ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp,td.OrderNumber ) as RowNumber
from    #TbWorkHistory as twh
		left join #TbDetail as td on td.ProfileID_td = twh.ProfileID
        left join #TbSumShift as tss on tss.ProfileID_tss = twh.ProfileID and td.OrderNumber = 1
        left join #TbSumBusinessLeave as tsbl on tsbl.ProfileID_tsbl = twh.ProfileID and td.OrderNumber = 1
        left join #TbSumLeaveDay as tsld on tsld.ProfileID_tsld = twh.ProfileID and td.OrderNumber = 1
        left join #TbSumOT as tso on tso.ProfileID_tso = twh.ProfileID and td.OrderNumber = 2
        left join #TbSumWorkDay as tswd on tswd.ProfileID_tswd = twh.ProfileID and td.OrderNumber = 1
		--left join #TbSumWorkDay as tswd2 on tswd2.ProfileID_tswd = twh.ProfileID and td.OrderNumber = 1
		left join #TbCountHaveShift as tchs on tchs.ProfileID = twh.ProfileID and td.OrderNumber = 1
		left join #SumNightShiftHours as snsh on snsh.ProfileID = twh.ProfileID and td.OrderNumber = 2
		OUTER APPLY ( SELECT TOP (1) agr.ProfileID FROM att_grade agr where agr.ProfileID = twh.ProfileID AND agr.MonthStart < @DateEnd AND agr.isdelete IS null ORDER BY agr.MonthStart DESC ) Agr
)
select * 
INTO	#Results
from	Results
where	1= 1 '+@TotalPaidDays+' '+@GradeAttendance+' '+@CheckData+' 
--and profileid =''84169C23-DC42-44A2-A216-815E0A04AEA6''
--and NS2 = 0.25
--and		codeemp = ''20171121003''

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

drop table #TbDetail, #TbOvertime, #tblPermission, #TbSumBusinessLeave, #TbSumLeaveDay, #TbSumOT, #TbSumShift, #TbSumWorkDay, #TbWorkday, #TbWorkHistory, #TempSTT, #Results;

Drop table #SumNightShiftHours

';
			
            exec (@Query + @Query2);
            --select  @ListShiftCode as ListShiftCode
            --      , @ListOverTimeType as ListOverTimeType
            --      , @ListLeaveDayCode as ListLeaveDayCode
            --      , @ListPaidLeaveDayCode as ListPaidLeaveDayCode
            --      , @ListNoPaidLeaveDayCode as ListNoPaidLeaveDayCode
            --      , @ListBusinessTravelCode as ListBusinessTravelCode
            --      , @ListCol as ListCol
            --      , @ListAlilas as ListAlilas
            --      , @MonthYear as MonthYear
            --      , @DateStart as DateStart
            --      , @DateEnd as DateEnd;

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

        --dr_BCCongChiTietThang
      end;
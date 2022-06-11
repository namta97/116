﻿---Nam Ta: 22/8/2021: Bang cong thang
ALTER proc rpt_Att_Monthly
@condition nvarchar(max) =  " and (MonthYear = '2021-09-01') and (CheckData like N'%E_POSTS%') ",
@PageIndex int = 1,
@PageSize int = 50000,
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

if ltrim(rtrim(@Condition)) = '' OR @Condition is null
begin
		set @Top = ' top 0 ';
		SET @condition =  ' and (MonthYear = ''2021-11-01'') '
end;

----Condition----
DECLARE @MonthYearCondition VARCHAR(100) = ' '
DECLARE @CheckData varchar(500) = ' '
DECLARE @EmpStatus NVARCHAR(500) = ' '
DECLARE @PaidWorkDayCount NVARCHAR(300) = ' ' 

-- cat dieu kien
set @str = REPLACE(@condition,',','@')
set @str = REPLACE(@str,'and (',',')
SELECT ID into #tableTempCondition FROM SPLIT_To_NVARCHAR (@str)
set @row = (SELECT count(ID) FROM SPLIT_To_NVARCHAR (@str))
set @countrow = 0
set @index = 0
while @row > 0
begin
	set @index = 0
	set @ID = (select top 1 ID from #tableTempCondition)
	set @tempID = replace(@ID,'@',',')

	set @index = 0
	set @index = charindex('MonthYear = ',@tempID,0) 
	if(@index > 0)
	begin
		set @tempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @MonthYearCondition = @tempCondition
	END

	set @index = charindex('(ProfileName ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
	END

	set @index = charindex('(CodeEmp ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(CodeEmp ','(hp.CodeEmp ')
	END

	set @index = charindex('(condi.EmploymentType ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.EmploymentType ','(hwh.EmploymentType ')
	END
    
	set @index = charindex('(condi.SalaryClassID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.SalaryClassID ','(hwh.SalaryClassID ')
	END

	set @index = charindex('(condi.PositionID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.PositionID ','(hwh.PositionID ')
	END
	
	set @index = charindex('(condi.JobTitleID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.JobTitleID ','(hwh.JobTitleID ')
	END
	
	set @index = charindex('(condi.WorkPlaceID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.WorkPlaceID ','(hwh.WorkPlaceID ')
	END
	
	set @index = charindex('(condi.EmployeeGroupID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.EmployeeGroupID ','(hwh.EmployeeGroupID ')
	END
		
	set @index = charindex('(condi.LaborType ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.LaborType ','(hwh.LaborType ')
	END

	set @index = charindex('(PayPaidType ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCondition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
	END

	set @index = charindex('CheckData ',@tempID,0)
	if(@index > 0)
	BEGIN
		set @tempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @CheckData = REPLACE(@tempCondition,'CheckData','')
		set @CheckData = REPLACE(@CheckData,'like N','')
		set @CheckData = REPLACE(@CheckData,'%','')
	END

	set @index = charindex('(condi.EmpStatus ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @EmpStatus = REPLACE(@tempCondition,'(condi.EmpStatus IN ','')
		set @EmpStatus = REPLACE(@EmpStatus,',',' OR ')
		set @EmpStatus = REPLACE(@EmpStatus,'))',')')
	END

	set @index = charindex('(PaidWorkDayCountP ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @PaidWorkDayCount = @tempCondition
	END

	DELETE #tableTempCondition WHERE ID = @ID
	SET @row = @row - 1
END

DROP TABLE #tableTempCondition

IF(@CheckData is not null and @CheckData <> '')
BEGIN
	SET @index = charindex('E_POSTS',@CheckData,0) 
	if(@index > 0)
	BEGIN
	SET @CheckData = REPLACE(@CheckData,'''E_POSTS''','AttendanceTableID IS NOT NULL ')
	END
	set @index = charindex('E_UNEXPECTED',@CheckData,0) 
	if(@index > 0)
	BEGIN
	set @CheckData = REPLACE(@CheckData,'''E_UNEXPECTED''','AttendanceTableID IS NULL ')
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

DECLARE @Getdata varchar(max)
DECLARE @Query nvarchar(max)
DECLARE @Query1 varchar(max)
DECLARE @Query2 varchar(max)
DECLARE @Query3 varchar(max)
DECLARE @queryPageSize varchar(max)

declare @ListNoPaidLeaveDayCode_Sum VARCHAR(max)
declare @ListPaidLeaveDayCode_Sum VARCHAR(max)
declare @ListPaidLeaveDay_AN_Sum VARCHAR(max)
declare @ListPaidLeaveDay_Other_Sum VARCHAR(max)
DECLARE @BusinessTravel_Sum VARCHAR(max) 
DECLARE @LeaveDayType VARCHAR(max) 
DECLARE @OverTimeType VARCHAR(max) 
DECLARE @BusinessTravel VARCHAR(max) 

SELECT @LeaveDayType = COALESCE(@LeaveDayType+',', '') +'['+ Code +']' FROM Cat_LeaveDayType where IsDelete is null  order by Code asc

SELECT @OverTimeType = COALESCE(@OverTimeType+',', '') +'['+ Code +']' FROM Cat_OvertimeType where IsDelete is null order by Code desc

SELECT @BusinessTravel = COALESCE(@BusinessTravel+',', '') +'['+ BusinessTravelCode +']' FROM Cat_BusinessTravel where IsDelete is null order by BusinessTravelCode desc

SELECT  @ListPaidLeaveDayCode_Sum = coalesce(@ListPaidLeaveDayCode_Sum + ' + ', '') + ' ISNULL(' + QUOTENAME(Code) + ',0)'
FROM    Cat_LeaveDayType
WHERE   IsDelete is null and PaidRate = 1 AND Code not in ('HLD')
ORDER BY Code
--SELECT @ListPaidLeaveDayCode_Sum

SELECT  @ListPaidLeaveDay_AN_Sum = coalesce(@ListPaidLeaveDay_AN_Sum + ' + ', '') + ' ISNULL(' + QUOTENAME(Code) + ',0)'
FROM    Cat_LeaveDayType
WHERE   IsDelete is null and PaidRate = 1 AND Code not in ('HLD') AND ( IsAnnualLeave = 1 OR Code = 'ADV' )
ORDER BY Code
--SELECT @ListPaidLeaveDay_AN_Sum

SELECT  @ListPaidLeaveDay_Other_Sum = coalesce(@ListPaidLeaveDay_Other_Sum + ' + ', '') + ' ISNULL(' + QUOTENAME(Code) + ',0)'
FROM    Cat_LeaveDayType
WHERE   IsDelete is null and PaidRate = 1 AND Code not in ('HLD') AND IsAnnualLeave <> 1 AND Code <> 'ADV'
ORDER BY Code
--SELECT @ListPaidLeaveDay_Other_Sum

SELECT  @ListNoPaidLeaveDayCode_Sum = coalesce(@ListNoPaidLeaveDayCode_Sum + ' + ', '') + ' ISNULL(' + QUOTENAME(Code) + ',0)'
FROM    Cat_LeaveDayType
WHERE   IsDelete is NULL AND (PaidRate = 0 OR PaidRate is null)  and Code not in ('DL')
ORDER BY Code;
--SELECT @ListNoPaidLeaveDayCode_Sum

SELECT  @BusinessTravel_Sum = coalesce(@BusinessTravel_Sum + ' + ', '') + ' ISNULL(' + QUOTENAME(BusinessTravelCode) + ',0)'
FROM    Cat_BusinessTravel
WHERE   IsDelete is NULL AND BusinessTravelCode not in ('WFH')
ORDER BY BusinessTravelCode;
--SELECT @BusinessTravel_Sum

SET @Getdata = '
	CREATE TABLE #tblPermission (id uniqueidentifier primary key )
	INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'

	--------------------------------Lay bang luong chinh-------------------------------------
	select s.* into #Att_AttendanceTable from Att_AttendanceTable s join #tblPermission tb on s.ProfileID = tb.ID
	where isdelete is null  '+@MonthYearCondition+'
	print(''#Att_AttendanceTable'')

	--- Lay ngay bat dau va ket thuc ky luong
	DECLARE @DateStart DATETIME, @DateEnd DATETIME, @StartMonth  DATETIME
	SELECT @DateStart = DateStart , @DateEnd = DateEnd, @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYearCondition+N'

	---Ngay ket thuc ky ung
	DECLARE @UnusualDay INT
	DECLARE @DateEndAdvance DATETIME

	SELECT @UnusualDay = value1 from Sys_AllSetting where isdelete is null and Name like ''%AL_Unusualpay_DaykeepUnusualpay%''
	SET @DateEndAdvance = DATEADD(DAY,@UnusualDay -1,@StartMonth)

		------------Ngay len chinh thuc----------------
	select ProfileID,DateEffective,ROW_NUMBER ( ) OVER (PARTITION BY ProfileID order by ProfileID,DateEffective desc) as flag
	into #LenChinhThuc
	from Hre_WorkHistory
	where isdelete is null and TypeOfTransferID in (SELECT id FROM Cat_NameEntity WHERE isdelete IS NULL AND NameEntityType = ''E_Typeoftransfer'' and Code = ''CTOP'')


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
SET @Query = '
	;WITH WorkHistory AS
	(
	select		' +@Top+ '
				hp.ID AS ProfileID , hp.CodeEmp, hp.ProfileName, cou.E_BRANCH AS DivisionName ,cou.E_UNIT AS CenterName,cou.E_DIVISION AS DepartmentName,cou.E_DEPARTMENT AS SectionName,cou.E_TEAM AS UnitName
				,csc.SalaryClassName,cp.PositionName,cj.JobTitleName,cetl.VN AS EmploymentType,cetl2.VN AS LaborType,cne.NameEntityName AS EmployeeGroupName, cwp.WorkPlaceName
				,hp.DateHire,hp.DateEndProbation,ct.DateEffective as LenChinhThuc,hp.DateQuit
				,@StartMonth AS MonthYear, cetl3.VN AS EmpStatus
				--So ngay chua vao lam va so ngay da thoi viec
				,CASE WHEN att.ID IS NOT NULL THEN dbo.fnc_NumberOfExceptWeekends(@DateStart,DATEADD(dd,-1,DateHire)) ELSE 0 END AS DaysBeforeHire
				,CASE WHEN att.ID IS NOT NULL THEN  dbo.fnc_NumberOfExceptWeekends(DateQuit,@DateEnd) ELSE 0 END AS DaysAfterQuit
				--So ngay lam viec
				,CASE WHEN att.ID IS NOT NULL THEN CASE WHEN dbo.fnc_NumberOfExceptWeekends(@DateStart,@DateEnd) > 22 THEN 22 ELSE dbo.fnc_NumberOfExceptWeekends(@DateStart,@DateEnd) END ELSE 0 END AS StdWorkDayCount
				,att.ID AS AttendanceTableID
	FROM		Hre_Profile hp
	LEFT JOIN	#Hre_WorkHistory hwh 
		ON		hp.ID = hwh.ProfileID 
	LEFT JOIN	#Att_AttendanceTable att 
		ON		hp.ID = att.ProfileID AND att.Isdelete IS NULL
				--AND att.ProfileID NOT IN ( SELECT ProfileID FROM Att_WorkDay WHERE ( Status IS NULL OR Status <> ''E_CONFIRMED'') AND WorkDate >= @DateStart AND WorkDate <= @DateEnd AND IsDelete IS NULL)
	LEFT JOIN	Cat_OrgStructure cos 
		ON		cos.ID = hwh.OrganizationStructureID
	LEFT JOIN	Cat_OrgUnit cou
		ON		cou.OrgstructureID = hwh.OrganizationStructureID
	LEFT JOIN	Cat_SalaryClass csc
		ON		csc.ID = hwh.SalaryClassID
	LEFT JOIN	Cat_JobTitle cj
		ON		cj.ID = hwh.JobTitleID
	LEFT JOIN	Cat_Position cp
		ON		cp.ID = hwh.PositionID
	LEFT JOIN	Cat_WorkPlace cwp 
		ON		cwp.ID = hwh.WorkPlaceID
	LEFT JOIN	Cat_NameEntity cne 
		ON		cne.ID = hwh.EmployeeGroupID
	LEFT JOIN	#LenChinhThuc ct 
		on		hwh.ProfileID = ct.ProfileID and ct.flag = ''1''
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

	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = att.EmpStatus 
						AND cetl.EnumKey in (''E_PROFILE_ACTIVE'',''E_PROFILE_QUIT'',''E_PROFILE_NEW'') AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl3
	OUTER APPLY	(
				SELECT	TOP(1) ag.GradeAttendanceID 
				FROM	dbo.Att_Grade ag
				WHERE	ag.ProfileID = hwh.ProfileID
						AND ag.MonthStart <= @DateEnd AND ( ag.MonthEnd IS NULL OR ag.MonthEnd >= @DateStart)
				ORDER BY ag.MonthStart DESC,ag.DateUpdate DESC
				) ag

	WHERE		hp.IsDelete is null
		AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart)
		AND		hp.DateHire <= @DateEnd
		AND		exists (Select * from #tblPermission tpm where id = hp.id )
				'+ISNULL(@condition,'')+'
				'+ISNULL(@EmpStatus,'')+'
	)
	SELECT	*
	INTO	#WorkHistory
	FROM	WorkHistory 
	WHERE	1 = 1
		'+ISNULL(@CheckData,'')+ ' 
	print(''#WorkHistory'');
	'

SET @Query1 = '
	SELECT		' +@Top+ '
				att.ProfileID,clt.Code AS CodeLeaveDay, ROUND(CASE WHEN atti.AvailableHours > 0 THEN atti.LeaveHours/ atti.AvailableHours ELSE 0 END,2 ) AS LeaveDays 
				,clt1.Code AS CodeExtraLeaveDay, ROUND(CASE WHEN atti.AvailableHours > 0 THEN atti.ExtraLeaveHours/ atti.AvailableHours ELSE 0 END,2 ) AS ExtraLeaveDays
				,clt3.Code AS CodeExtraLeaveDay3, ROUND(CASE WHEN atti.AvailableHours > 0 THEN atti.ExtraLeaveHours3/ atti.AvailableHours ELSE 0 END,2 )  AS ExtraLeaveDays3
				,clt4.Code AS CodeExtraLeaveDay4, ROUND(CASE WHEN atti.AvailableHours > 0 THEN atti.ExtraLeaveHours4/ atti.AvailableHours ELSE 0 END,2 )  AS ExtraLeaveDays4
				,clt5.Code AS CodeExtraLeaveDay5, ROUND(CASE WHEN atti.AvailableHours > 0 THEN atti.ExtraLeaveHours5/ atti.AvailableHours ELSE 0 END,2 )  AS ExtraLeaveDays5
				,clt6.Code AS CodeExtraLeaveDay6, ROUND(CASE WHEN atti.AvailableHours > 0 THEN atti.ExtraLeaveHours6/ atti.AvailableHours ELSE 0 END,2 )  AS ExtraLeaveDays6
				,cot.Code AS CodeOvertime, atti.OvertimeHours
				,cot1.Code AS CodeExtraOvertime, atti.ExtraOvertimeHours
				,cot2.Code AS CodeExtraOvertime2, atti.ExtraOvertimeHours2
				,cot3.Code AS CodeExtraOvertime3, atti.ExtraOvertimeHours3
				,cot4.Code AS CodeExtraOvertime4, atti.ExtraOvertimeHours4
				,cbt1.BusinessTravelCode AS BusinessTravelCode1, atti.BusinessTravelDay1
				,cbt2.BusinessTravelCode AS BusinessTravelCode2, atti.BusinessTravelDay2
				,atti.LateInMinutes2,atti.EarlyOutMinutes2,atti.WorkPaidHours
				,atti.NightShiftHours,atti.AvailableHours
	INTO		#DataMain
	FROM		#Att_AttendanceTable att
	LEFT JOIN	Att_AttendanceTableItem atti
		ON		att.ID = atti.AttendanceTableID
				AND atti.IsDelete IS NULL
	LEFT JOIN	Cat_LeaveDayType clt
		ON		atti.LeaveTypeID = clt.ID AND clt.IsDelete IS NULL
	LEFT JOIN	Cat_LeaveDayType clt1
		ON		atti.ExtraLeaveTypeID = clt1.ID AND clt1.IsDelete IS NULL
	LEFT JOIN	Cat_LeaveDayType clt3
		ON		atti.ExtraLeaveType3ID = clt3.ID AND clt3.IsDelete IS NULL
	LEFT JOIN	Cat_LeaveDayType clt4
		ON		atti.ExtraLeaveType4ID = clt4.ID AND clt4.IsDelete IS NULL
	LEFT JOIN	Cat_LeaveDayType clt5
		ON		atti.ExtraLeaveType5ID = clt5.ID AND clt5.IsDelete IS NULL
	LEFT JOIN	Cat_LeaveDayType clt6
		ON		atti.ExtraLeaveType6ID = clt6.ID AND clt6.IsDelete IS NULL
	LEFT JOIN	Cat_OvertimeType cot
		ON		atti.OvertimeTypeID = cot.ID AND cot.IsDelete IS NULL
	LEFT JOIN	Cat_OvertimeType cot1
		ON		atti.ExtraOvertimeTypeID = cot1.ID AND cot1.IsDelete IS NULL
	LEFT JOIN	Cat_OvertimeType cot2
		ON		atti.ExtraOvertimeType2ID = cot2.ID AND cot2.IsDelete IS NULL
	LEFT JOIN	Cat_OvertimeType cot3 
		ON		atti.ExtraOvertimeType3ID = cot3.ID AND cot3.IsDelete IS NULL
	LEFT JOIN	Cat_OvertimeType cot4
		ON		atti.ExtraOvertimeType4ID = cot4.ID AND cot4.IsDelete IS NULL
	LEFT JOIN	Cat_BusinessTravel cbt1
		ON		cbt1.ID = atti.BusinessTravelTypeID1
	LEFT JOIN	Cat_BusinessTravel cbt2
		ON		cbt2.ID = atti.BusinessTravelTypeID2
	WHERE		atti.WorkDate >= @DateStart AND atti.WorkDate <= @DateEnd
				--AND att.ProfileID NOT IN ( SELECT ProfileID FROM Att_WorkDay WHERE ( Status IS NULL OR Status <> ''E_CONFIRMED'') AND WorkDate >= @DateStart AND WorkDate <= @DateEnd AND IsDelete IS NULL)
				and exists ( select * from   #WorkHistory as twh where  twh.ProfileID = att.ProfileID );
	'
set @Query2 = '
	-----------Pivot so ngay nghi theo tung loai ngay nghi--------------------------------------------
	 ;WITH LeaveDay AS
	(
	SELECT		ProfileID,CodeLeaveDay AS CodeLeaveDay,LeaveDays AS LeaveDays FROM #DataMain WHERE LeaveDays > 0
	UNION ALL
	SELECT		ProfileID,CodeExtraLeaveDay AS CodeLeaveDay,ExtraLeaveDays AS LeaveDays FROM #DataMain WHERE ExtraLeaveDays > 0
	UNION ALL
	SELECT		ProfileID,CodeExtraLeaveDay3 AS CodeLeaveDay,ExtraLeaveDays3 AS LeaveDays FROM #DataMain WHERE ExtraLeaveDays3 > 0
	UNION ALL
	SELECT		ProfileID,CodeExtraLeaveDay4 AS CodeLeaveDay,ExtraLeaveDays4 AS LeaveDays FROM #DataMain WHERE ExtraLeaveDays4 > 0
	UNION ALL
	SELECT		ProfileID,CodeExtraLeaveDay5 AS CodeLeaveDay,ExtraLeaveDays5 AS LeaveDays FROM #DataMain WHERE ExtraLeaveDays5 > 0
	UNION ALL
	SELECT		ProfileID,CodeExtraLeaveDay6 AS CodeLeaveDay,ExtraLeaveDays6 AS LeaveDays FROM #DataMain WHERE ExtraLeaveDays6 > 0
	)
	SELECT * into #LeaveDayPivot FROM LeaveDay 
	PIVOT (sum(LeaveDays) for CodeLeaveDay in ('+@LeaveDayType+')) P

	-----------Pivot gio tang ca theo tung loại tang ca-------------
	 ;WITH OverTime AS
	(
	SELECT		ProfileID,CodeOvertime AS CodeOvertime,OvertimeHours AS OvertimeHours FROM #DataMain WHERE OvertimeHours > 0
	UNION ALL
	SELECT		ProfileID,CodeExtraOvertime AS CodeOvertime,ExtraOvertimeHours AS OvertimeHours FROM #DataMain WHERE ExtraOvertimeHours > 0
	UNION ALL
	SELECT		ProfileID,CodeExtraOvertime2 AS CodeOvertime,ExtraOvertimeHours2 AS OvertimeHours FROM #DataMain WHERE ExtraOvertimeHours2 > 0
	UNION ALL
	SELECT		ProfileID,CodeExtraOvertime3 AS CodeOvertime,ExtraOvertimeHours3 AS OvertimeHours FROM #DataMain WHERE ExtraOvertimeHours3 > 0
	UNION ALL
	SELECT		ProfileID,CodeExtraOvertime4 AS CodeOvertime,ExtraOvertimeHours4 AS OvertimeHours FROM #DataMain WHERE ExtraOvertimeHours4 > 0
	)
	SELECT * into #OvertimePivot FROM OverTime 
	PIVOT (sum(OvertimeHours) for CodeOvertime in ('+@OverTimeType+')) P

	-----------Pivot so ngay nghi cong tac theo tung loại di cong tac------
	 ;WITH BusinessTravel AS
	(
	SELECT ProfileID,BusinessTravelCode1 AS BusinessTravelCode,BusinessTravelDay1 AS BusinessTravelDays from #DataMain where BusinessTravelDay1 > 0
	UNION ALL
	SELECT ProfileID,BusinessTravelCode2 AS BusinessTravelCode,BusinessTravelDay2 AS BusinessTravelDays from #DataMain where BusinessTravelDay2 > 0
	)
	SELECT * into #BusinessTravelPivot FROM BusinessTravel 
	PIVOT (sum(BusinessTravelDays) for BusinessTravelCode in ('+@BusinessTravel+')) P

	---------------------Lay gio dang ky ke hoach tang ca----------------
	 ;WITH OverTimePlan AS
	 (
	select		otp.ProfileID, otp.RegisterHours 
	FROM		Att_OvertimePlan otp
	INNER JOIN	Att_Workday aw
		ON		aw.WorkDate = otp.WorkDateRoot AND otp.ProfileID = aw.ProfileID
	WHERE		otp.IsDelete is null and otp.RegisterHours > 0 and otp.Status=''E_APPROVED''
				and @DateStart <= otp.WorkDateRoot and @DateEnd >= otp.WorkDateRoot
				AND aw.IsDelete IS NULL AND aw.Status = ''E_CONFIRMED''
	)
	select ProfileID, sum(RegisterHours) as RegisterHours into #OvertimePlan from OverTimePlan group by ProfileID 

	----------Lay tre som chuyen can---
	 ;WITH LateEarly AS
	 (
	select d.ProfileID,d.LateInMinutes2,d.EarlyOutMinutes2 from #DataMain d 
	where (d.LateInMinutes2 > 0 or d.EarlyOutMinutes2 > 0)
	)
	select ProfileID,sum(LateInMinutes2) as LateInMinutes2,sum(EarlyOutMinutes2) as EarlyOutMinutes2 into #LateEarlyMinutes from LateEarly group by ProfileID 
	'
set @Query3 = '
	---------Dem so ngay di lam thuc te----------
	 ;WITH RealWorkDayCount AS
	(
	select ProfileID, ROUND(CASE WHEN AvailableHours > 0 THEN WorkPaidHours/ AvailableHours ELSE 0 END,2 ) AS RealWorkDayCount from #DataMain d where WorkPaidHours > 0
	)
	select ProfileID,sum(RealWorkDayCount) as RealWorkDayCount into #RealWorkDayCount from RealWorkDayCount group by ProfileID 

	----------Dem so phut nightshift---
	 ;WITH NightShiftHours AS
	 (
	select ProfileID, NightShiftHours from #DataMain d 
	where NightShiftHours > 0
	)
	select ProfileID,sum(NightShiftHours) as NightShiftHours into #NightShiftHours from NightShiftHours group by ProfileID 


	---------------------------------------------------select ket qua cuoi-------------------------------------------------------------------------------
	select hwh.*
	,' +ISNULL(@ListNoPaidLeaveDayCode_Sum,0)+ ' AS NotPaidWorkDayCountP
	,ISNULL(DL,0) as PaidQuitJobDayCount
	,ISNULL(RealWorkDayCount,0) + ISNULL(HLD,0) + ' +ISNULL(@ListPaidLeaveDayCode_Sum,0)+ ' +ISNULL(WFH,0) + ' +ISNULL(@BusinessTravel_Sum,0)+ ' AS PaidWorkDayCountP
	,ISNULL(RealWorkDayCount,0) as RealWorkDayCount
	,ISNULL(WFH,0) AS WFHCount
	--Phep nam va Ngay nghi cong tac
	,ISNULL(HLD,0) as HLD
	,' +ISNULL(@BusinessTravel_Sum,0)+ ' as TongSoNgayCTac
	,ISNULL(BTS2,0) as DiCTacBTS2,ISNULL(BTS1,0) as DiCTacBTS1,ISNULL(BTOS,0) as DiCTacBTOS,ISNULL(BTL,0) as DiCTacBTL,ISNULL(BTOL,0) as DiCTacBTOL
	---Phep nam
	,' +ISNULL(@ListPaidLeaveDay_AN_Sum,0)+ ' as TongPhepNamP
	,ISNULL(AN,0) as AN,ISNULL(AN1,0) as AN1,ISNULL(ADV,0) as ADV
	,' +@ListPaidLeaveDay_Other_Sum+ ' as OtherPaidLeaveP
	,ISNULL(M,0) as M,ISNULL(CM,0) as CM,ISNULL(F,0) as F,ISNULL(ML,0) as ML,ISNULL(MLT,0) as MLT,ISNULL(C,0) as C,NULL as OTC,ISNULL(A,0) as A
	,ISNULL(DL,0) as DL
	,' +ISNULL(@ListNoPaidLeaveDayCode_Sum,0)+ ' AS NghiPhepKoLuongP
	,ISNULL(MH1,0) as MH1,ISNULL(DS1,0) as DS1,ISNULL(DS2,0) as DS2,ISNULL(SIB7,0) as SIB7,ISNULL(SIB6,0) as SIB6,ISNULL(SS,0) as SS,ISNULL(NAT,0) as NAT,ISNULL(CS3,0) as CS3,ISNULL(CS7,0) as CS7,ISNULL(SIB4,0) as SIB4,ISNULL(LS,0) as LS
	,ISNULL(SM,0) as SM,ISNULL(RA,0) as RA,ISNULL(FP,0) as FP,ISNULL(NP,0) as NP,ISNULL(WP,0) as WP,ISNULL(WP1,0) as WP1
	--Gio dang ky tang ca ke hoach
	,ISNULL(op.RegisterHours,0) AS RegisterHours
	---Tang ca
	,ISNULL(E_WORKDAY,0)+ISNULL(E_WORKDAY_NIGHTSHIFT,0) +ISNULL(E_WEEKEND,0)+ISNULL(E_WEEKEND_NIGHTSHIFT,0) +ISNULL(E_HOLIDAY,0)+ISNULL(E_HOLIDAY_NIGHTSHIFT,0)
	AS TongOTttP
	,ISNULL(E_WORKDAY,0)+ISNULL(E_WORKDAY_NIGHTSHIFT,0)
	AS OT1ttP
	,ISNULL(E_WEEKEND,0)+ISNULL(E_WEEKEND_NIGHTSHIFT,0)
	AS OT2ttP
	,ISNULL(E_HOLIDAY,0)+ISNULL(E_HOLIDAY_NIGHTSHIFT,0)
	as OT2HttP
	-----Ca dem
	,ROUND(ISNULL(nsh.NightShiftHours,0)*2,0)/2+ISNULL([E_WORKDAY_NIGHTSHIFT],0)+ISNULL([E_WEEKEND_NIGHTSHIFT],0)+ISNULL([E_HOLIDAY_NIGHTSHIFT],0) as TongNSP
	,ROUND(ISNULL(nsh.NightShiftHours,0)*2,0)/2 as NS1,ISNULL(E_WORKDAY_NIGHTSHIFT,0) as NS2,ISNULL(E_WEEKEND_NIGHTSHIFT,0) as NS3,ISNULL(E_HOLIDAY_NIGHTSHIFT,0) as NS4
	-----So phut tre som
	,(ISNULL(le.LateInMinutes2,0)+ISNULL(le.EarlyOutMinutes2,0))/60 as TongTreSomP
	,GETDATE() AS DateExport
	--DkLoc
	,NULL AS "cos.OrderNumber",NULL AS "condi.EmploymentType",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation"
	,NULL AS "hp.DateQuit",NULL AS "condi.WorkPlaceID",NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType"
	,NULL AS "condi.EmpStatus",NULL AS "CheckData", NULL AS "ag.GradeAttendanceID"
	INTO #Results
	from #WorkHistory hwh
	left join #LeaveDayPivot l on hwh.ProfileID = l.ProfileID
	left join #OvertimePivot o on hwh.ProfileID = o.ProfileID
	left join #OvertimePlan op on hwh.ProfileID = op.ProfileID
	left join #BusinessTravelPivot b on hwh.ProfileID = b.ProfileID
	left join #LateEarlyMinutes le on hwh.ProfileID = le.ProfileID
	left join #RealWorkDayCount cw on hwh.ProfileID = cw.ProfileID
	left join #NightShiftHours nsh on hwh.ProfileID = nsh.ProfileID
	'
set @queryPageSize = '

	SELECT ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as STT,* 
	FROM  #Results
	WHERE 1 = 1 '+@PaidWorkDayCount+' 
	ORDER BY STT
	drop table #tblPermission, #DataMain, #LeaveDayPivot, #OvertimePivot, #BusinessTravelPivot, #OvertimePlan, #LateEarlyMinutes, #RealWorkDayCount, #LenChinhThuc,#Att_AttendanceTable, #NightShiftHours,#WorkHistory,#Results, #Hre_WorkHistory
	'

print (@Getdata)
print (@Query)
print (@Query1)
print (@Query2)
print (@Query3)
print (@queryPageSize)

exec( @Getdata+' '+@Query+ @Query1+'  '+@Query2+' '+@Query3 +@queryPageSize)
END

--rpt_Att_Monthly
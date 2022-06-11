--- 30/07/2021 Nam Ta: Dem so ngay nghi khong luong cua nhan vien - sp phuc vu cho Reason of without having advance salary

alter proc [dbo].[Countleaveday_EachEmployee]
@condition varchar(max) =   "and (MonthYear = '2021-09-01')  ",
@IsAdvance INT = 0, -- 1 = Advance
@PageIndex int = 1,
@PageSize int = 50000,
@Username varchar(100) = 'Khang.Nguyen'
as
BEGIN

 declare @str varchar(max)
 declare @countrow int
 declare @row int
 declare @index int
 declare @ID varchar(200)

-- ma loai ngay nghi khong luong 
DECLARE @col_ld NVARCHAR(max)
SELECT @col_ld = COALESCE(@col_ld+',', '') +'['+ Code +']' FROM Cat_LeaveDayType where IsDelete is NULL  AND PaidRate = 0  AND IsInactive = 0 order by Code asc

--Dieu kien noi chuoi ly do
DECLARE @CaseWhen NVARCHAR(max)
SET @CaseWhen = N'';
SELECT @CaseWhen += N' + CASE WHEN ' + CodeStatistic + ' IS NOT NULL THEN ''' +' | ' +CodeStatistic + ': '+ ''' ' +'+ CONVERT(NVARCHAR(10),'+CodeStatistic+') ELSE '''' END'
FROM Cat_LeaveDayType 
WHERE IsDelete is null and [Order]is not null AND PaidRate = 0
order by IsInsuranceLeave,IsWorkDay,IsBusinessTravel,IsAnnualLeave desc,PaidRate,SocialRate;
set @CaseWhen= substring(@CaseWhen,charindex('+',@CaseWhen)+1, len(@CaseWhen))

-- lay ra monthyear
DECLARE @MonthYear VARCHAR(12)
SET @MonthYear = SUBSTRING(REPLACE(@condition,' ',''),CHARINDEX('=',REPLACE(@condition,' ',''),1) + 2,10)

DECLARE @DateStart DATETIME, @DateEnd DATETIME, @StartMonth  DATETIME
SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL AND MonthYear = @MonthYear

---Ngay ket thuc ky ung
DECLARE @UnusualDay INT
DECLARE @DateEndAdvance DATETIME

SELECT @UnusualDay = value1 from Sys_AllSetting where isdelete is null and Name like '%AL_Unusualpay_DaykeepUnusualpay%'
SET @DateEndAdvance = DATEADD(DAY,@UnusualDay -1,@StartMonth)

--[Countleaveday_EachEmployee]
---Dieu kien Advance Or Salary

DECLARE @AdvanceORSalary NVARCHAR(200) =''
IF @IsAdvance = 1
BEGIN
SET @AdvanceORSalary = ' AND  ai.WorkDate <= '''+CONVERT(VARCHAR(30),@DateEndAdvance,103)+'''' 
END


declare @Query1 nvarchar(max)
declare @Query2 nvarchar(max)
declare @Query3 nvarchar(max) 


set @Query1 ='	
	SELECT 	a.ID,a.ProfileID,a.CutOffDurationID,a.PaidWorkDayCount,a.AnlDayTaken,a.OrgStructureID,a.WorkPlaceID,a.PositionID,a.PayrollGroupID
	,a.LeaveDay1Type,a.LeaveDay1Days,
	a.LeaveDay2Type,a.LeaveDay2Days,a.LeaveDay3Type,a.LeaveDay3Days
	,a.LeaveDay4Type,a.LeaveDay4Days,a.LeaveDay5Type,a.LeaveDay5Days,a.LeaveDay6Type,a.LeaveDay6Days
	,a.Isdelete
	INTO #AttendanceTable 
	FROM Att_AttendanceTable a  
	WHERE IsDelete is null '+@condition+'

	SELECT a.*,ai.WorkDate,ai.WorkPaidHours,ai.LeaveTypeID,ai.ExtraLeaveTypeID,ai.ExtraLeaveHours
	,ai.LeaveHours,ai.ShiftID
	,ai.AttendanceTableID
	,ai.LateInMinutes,ai.EarlyOutMinutes,ai.LateEarlyMinutes,ai.DutyCode,ai.FirstInTime,
	ai.ExtraLeaveHours3,ai.ExtraLeaveHours4,ai.ExtraLeaveHours5, ai.ExtraLeaveHours6,
	ai.ExtraLeaveType3ID,ai.ExtraLeaveType4ID,ai.ExtraLeaveType5ID,ai.ExtraLeaveType6ID
	INTO #AttendanceTableItem 
	FROM #AttendanceTable a 
	LEFT JOIN Att_AttendanceTableItem ai 
	ON a.ID = ai.AttendanceTableID
	'+@AdvanceORSalary+'
	DROP TABLE #AttendanceTable
		'	
	
set @Query2='
	SELECT  att.ProfileID,ai.AttendanceTableID, ai.ShiftID,
			DATEPART(DAY, ai.WorkDate) as WorkDate, 
			ROUND( isnull(ai.LeaveHours,0),2) as LeaveHours,ld.CodeStatistic as LeaveDayType, 
			ROUND(isnull( ai.ExtraLeaveHours,0),2) as ExtraLeaveHours, extld.CodeStatistic   as ExtraLeave,
			ROUND( isnull(ai.ExtraLeaveHours3,0),2) as ExtraLeaveHours3, extld3.CodeStatistic as ExtraLeave3,
			ROUND( isnull(ai.ExtraLeaveHours4,0),2) as ExtraLeaveHours4, extld4.CodeStatistic as ExtraLeave4,
			ROUND( isnull(ai.ExtraLeaveHours5,0),2) as ExtraLeaveHours5, extld5.CodeStatistic as ExtraLeave5,
			ROUND(isnull( ai.ExtraLeaveHours6,0),2) as ExtraLeaveHours6, extld6.CodeStatistic as ExtraLeave6,
			concat(
			case ai.LeaveHours
				when 0 then ''''
				when null then ''''
				else cast(ROUND(ai.LeaveHours,2) as nvarchar(10))+''-''+ ld.CodeStatistic
			end,
			case ai.ExtraLeaveHours
				when 0 then ''''
				when null then ''''
				else ''/ ''+cast(ROUND(ai.ExtraLeaveHours,2) as nvarchar(10))+''-''+ extld.CodeStatistic
			end,
			case ai.ExtraLeaveHours3
				when 0 then ''''
				when null then ''''
				else ''/''+cast(ROUND(ai.ExtraLeaveHours3,2) as nvarchar(10))+''-''+ extld3.CodeStatistic
			end,
			case ai.ExtraLeaveHours4
				when 0 then ''''
				when null then ''''
				else ''/''+cast(ROUND(ai.ExtraLeaveHours4,2) as nvarchar(10))+''-''+ extld4.CodeStatistic
			end,
			case ai.ExtraLeaveHours5
				when 0 then ''''
				when null then ''''
				else ''/''+cast(ROUND(ai.ExtraLeaveHours5,2) as nvarchar(10))+''-''+ extld5.CodeStatistic
			end,
			case ai.ExtraLeaveHours6
				when 0 then ''''
				when null then ''''
				else ''/''+cast(ROUND(ai.ExtraLeaveHours6,2) as nvarchar(10))+''-''+ extld6.CodeStatistic
			end
			) as DataAtt
	INTO	#LDDetail
	FROM	#AttendanceTableItem ai
	LEFT JOIN Cat_LeaveDayType ld		ON ld.id = ai.LeaveTypeID
	LEFT JOIN Cat_LeaveDayType extld	ON extld.id = ai.ExtraLeaveTypeID
	LEFT JOIN Cat_LeaveDayType extld3	ON extld3.id = ai.ExtraLeaveType3ID
	LEFT JOIN Cat_LeaveDayType extld4	ON extld4.id = ai.ExtraLeaveType4ID
	LEFT JOIN Cat_LeaveDayType extld5	ON extld5.id = ai.ExtraLeaveType5ID
	LEFT JOIN Cat_LeaveDayType extld6	ON extld6.id = ai.ExtraLeaveType6ID
	LEFT JOIN Att_AttendanceTable att	ON att.id= ai.AttendanceTableID
	WHERE	ai.LeaveTypeID is not null
			AND ai.AttendanceTableID in (SELECT id FROM Att_AttendanceTable WHERE IsDelete is null)
	'
--- Pivot tong so ngay nghi theo tung loai ngay nghi
set @Query3 ='

	SELECT		L.ProfileID as ProfileID,l.LeaveDayType as DataType, 
				(ISNULL(L.TotalLeaveDay,0)+
				ISNULL( E.TotalExtraLeaveDay,0)+
				ISNULL( E3.TotalExtraLeaveDay3,0)+
				ISNULL( E4.TotalExtraLeaveDay4,0)) as Total
	INTO		#TotalLeveday 
	FROM		(
					SELECT ProfileID,AttendanceTableID,LeaveDayType,
					round(SUM(ld.LeaveHours/cs.WorkHours) ,2)as TotalLeaveDay,
					SUM(ld.LeaveHours) as TotalLeaveHours
					FROM #LDDetail ld 
					LEFT JOIN Cat_Shift cs
					ON cs.ID = ld.ShiftID
					group by ProfileID, AttendanceTableID,LeaveDayType
				) as L
	LEFT JOIN	(
					SELECT	ProfileID,AttendanceTableID,ExtraLeave,
					round(SUM(ld.ExtraLeaveHours/cs.WorkHours) ,2)as TotalExtraLeaveDay,
					sum(ld.ExtraLeaveHours) as TotalExtraLeaveHours
					FROM #LDDetail ld 
					LEFT JOIN Cat_Shift cs
					ON cs.ID = ld.ShiftID
					WHERE ExtraLeave is not null
					group by ProfileID, AttendanceTableID,ExtraLeave
				) E
		ON		L.LeaveDayType = E.ExtraLeave AND L.ProfileID = E.ProfileID AND	L.AttendanceTableID = E.AttendanceTableID

	LEFT JOIN	(
					SELECT ProfileID,AttendanceTableID,ExtraLeave3,
					round(SUM(ld.ExtraLeaveHours3/cs.WorkHours) ,2)as TotalExtraLeaveDay3,
					sum(ld.ExtraLeaveHours3) as TotalExtraLeaveHours3
					FROM #LDDetail ld 
					LEFT JOIN Cat_Shift cs	ON cs.ID = ld.ShiftID
					WHERE ExtraLeave3 is not null
					group by ProfileID, AttendanceTableID,ExtraLeave3
				) as E3
		ON		L.LeaveDayType = E3.ExtraLeave3 AND	L.ProfileID = E3.ProfileID AND L.AttendanceTableID = E3.AttendanceTableID

	LEFT JOIN	(
					SELECT ProfileID,AttendanceTableID,ExtraLeave4,
					round(SUM(ld.ExtraLeaveHours4/cs.WorkHours) ,2)as TotalExtraLeaveDay4,
					sum(ld.ExtraLeaveHours4) as TotalExtraLeaveHours4
					FROM #LDDetail ld 
					LEFT JOIN Cat_Shift cs	ON cs.ID = ld.ShiftID
					WHERE ExtraLeave4 is not null
					group by ProfileID, AttendanceTableID,ExtraLeave4
				) as E4
		ON		L.LeaveDayType = E4.ExtraLeave4 AND	L.ProfileID = E4.ProfileID AND L.AttendanceTableID = E4.AttendanceTableID

	SELECT		* 
	INTO		#GeneralLD
	FROM		#TotalLeveday 
	PIVOT		(sum(Total) for DataType in ([LeavedayTypeList])) as p;

	SELECT	ProfileID,[CaseWhenLeave] AS ReasonLeave
	INTO	#ReasonLeaveDay
	FROM	#GeneralLD


	UPDATE	#ReasonLeaveDay
	SET		ReasonLeave = substring(ReasonLeave,charindex(''|'',ReasonLeave)+2, len(ReasonLeave))

	SELECT * from #ReasonLeaveDay

	DROP TABLE #LDDetail
	DROP TABLE #TotalLeveday
	DROP TABLE #ReasonLeaveDay

	'	

	set @Query3 = REPLACE(@Query3,'[LeavedayTypeList]',@col_ld)
	set @Query3 = REPLACE(@Query3,'[CaseWhenLeave]',@CaseWhen)

	--print(@Query1)
	--print(@query2) 
	--print(@query3)
	exec  (@Query1+''+@Query2+''+@Query3)
	
END
--[Countleaveday_EachEmployee]

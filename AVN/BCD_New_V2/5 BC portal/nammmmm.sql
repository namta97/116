ALTER PROCEDURE [dbo].[hrm_att_sp_get_TimeSheetByEmployee_nam]  
 @CutOffDurationID UNIQUEIDENTIFIER = NULL,  
 @strOrgIds VARCHAR(MAX) = NULL,  
 @ProfileIDs VARCHAR(MAX) = NULL,  
 @DateHireFrom DATETIME = NULL,  
 @DateHireTo DATETIME = NULL,  
 @DateQuitFrom DATETIME = NULL,  
 @DateQuitTo DATETIME = NULL,  
 @Status VARCHAR(MAX) = NULL,  
 @PageIndex INT = 1,  
 @PageSize INT = 50,  
 @UserName NVARCHAR(50) = 'nam.vu',  
 @fieldSort VARCHAR(50) = 'id'  
AS  
BEGIN  
 SET NOCOUNT ON;  
 set @DateHireFrom = CAST(@DateHireFrom AS DATE)  
 set @DateHireTo = DATEADD(day, 1, CAST(@DateHireTo AS DATE))  
 set @DateQuitFrom = CAST(@DateQuitFrom AS DATE)  
 set @DateQuitTo = DATEADD(day, 1, CAST(@DateQuitTo AS DATE))  
 --Prepair paramater  
 DECLARE @DefinePermission NVARCHAR(MAX) = N''  
  + N' SELECT * INTO #tblEnumStatus FROM dbo.GetEnumValueNew (''ComputeAttendanceStatus'', @UserName)  
    CREATE TABLE #tblPermission (id UNIQUEIDENTIFIER PRIMARY KEY )   
    INSERT INTO #tblPermission EXEC Get_Data_Permission_New @Username, ''Att_AttendanceTable'' '  
 DECLARE @DefineEnum NVARCHAR(MAX) = N''  
  + N'  
    IF @strOrgIds IS NOT NULL  
    BEGIN  
     SELECT Id INTO #OrgIdFilter FROM split_to_int(ISNULL(@strOrgIds, NULL))  
    END  
  
    IF @ProfileIDs IS NOT NULL  
    BEGIN  
    SELECT orgId INTO #ProfileFilter FROM GetOrgTableIds(ISNULL(@ProfileIDs, NULL))  
    END  
  
    IF @Status IS NOT NULL  
    BEGIN  
    SELECT Id INTO #StatusFilter FROM SPLIT_To_VARCHAR(ISNULL(@Status, NULL))  
    END  
   '  
 --M?nh �? FROM  
 DECLARE @ClauseFrom NVARCHAR(MAX) = N''  
  + N' FROM Att_AttendanceTable aad' + CHAR(10)  
  + N' JOIN Hre_Profile hp WITH (NOLOCK) ON aad.ProfileID = hp.ID  
    LEFT JOIN Cat_OrgStructure co ON aad.OrgStructureID = co.ID AND co."IsDelete" IS NULL  
     JOIN #tblPermission fcP ON fcP.Id = aad.ProfileID ' + CHAR(10)  
 -- M?nh �? FROM main  
 DECLARE @ClauseFromMain NVARCHAR(MAX) = N''  
  + N' FROM Att_AttendanceTable aad' + CHAR(10)  
  + N' JOIN Hre_Profile hp WITH (NOLOCK) ON aad."ProfileID" = hp.ID  
    LEFT JOIN Cat_OrgStructure co ON aad."OrgStructureID" = co.ID AND co."IsDelete" IS NULL  
    LEFT JOIN Cat_Position cp ON aad.PositionID = cp.ID AND cp.IsDelete IS NULL  
    LEFT JOIN Cat_JobTitle cj ON aad.JobTitleID = cj.ID AND cj.IsDelete IS NULL  
    LEFT JOIN #tblEnumStatus est ON est.EnumKey = aad.Status  
    LEFT JOIN Sys_UserInfo su ON aad.UserApproveID = su.Id AND su."IsDelete" IS NULL  
    LEFT JOIN Sys_UserInfo su2 ON aad.UserApproveID2 = su2.Id AND su2."IsDelete" IS NULL  
    LEFT JOIN Sys_UserInfo su3 ON aad.UserApproveID3 = su3.Id and su3."IsDelete" IS NULL  
    LEFT JOIN Sys_UserInfo su4 ON aad.UserApproveID4 = su4.Id and su4."IsDelete" IS NULL  
    LEFT JOIN Cat_SalaryClass csc ON csc.ID = aad.SalaryClassID AND csc.IsDelete IS NULL  
    LEFT JOIN Sys_UserInfo rj1 ON aad.UserRejectID = rj1.ID and rj1.IsDelete IS NULL 
	LEFT JOIN #Results rs ON rs.ProfileID = hp.ID
     JOIN #tblPermission fcP ON fcP.Id = aad.ProfileID ' + CHAR(10)  
  
 --M?nh �? WHERE  
 DECLARE @ClauseWhere NVARCHAR(MAX) = N' WHERE ' + CHAR(10)  
  + N' aad.IsDelete IS NULL AND aad.CutOffDurationID = @CutOffDurationID '  
  + N'AND hp."ID" NOT IN (SELECT ID from Hre_Profile where StatusSyn = ''E_WAITING_APPROVE'')'  
 IF @ProfileIDs IS NOT NULL  
  SET @ClauseWhere = @ClauseWhere + CHAR(10)  
   + N' AND (aad.ProfileID IN (SELECT orgId FROM #ProfileFilter)) '   
 IF @strOrgIds IS NOT NULL  
  SET @ClauseWhere = @ClauseWhere + CHAR(10)  
   + N' AND (co.OrderNumber in (SELECT Id FROM #OrgIdFilter)) '  
 IF @DateHireFrom IS NOT NULL  
  SET @ClauseWhere = @ClauseWhere + CHAR(10)  
   + N' AND (hp.DateHire >= @DateHireFrom) '  
 IF @DateHireTo IS NOT NULL  
  SET @ClauseWhere = @ClauseWhere + CHAR(10)  
   + N' AND (hp.DateHire < @DateHireTo) '  
 IF @DateQuitFrom IS NOT NULL  
  SET @ClauseWhere = @ClauseWhere + CHAR(10)  
   + N' AND (hp.DateQuit >= @DateQuitFrom) '  
 IF @DateQuitTo IS NOT NULL  
  SET @ClauseWhere = @ClauseWhere + CHAR(10)  
   + N' AND (hp.DateQuit < @DateQuitTo) '  
 IF @Status IS NOT NULL  
  SET @ClauseWhere = @ClauseWhere + CHAR(10)  
   + N' AND (aad.Status in (SELECT Id FROM #StatusFilter)) '  
  
 DECLARE @ClauseSelect NVARCHAR(MAX) = N''  
 + N' SELECT  
   @TotalRow as TotalRow,  
   rs.*,  
   hp.CodeEmp,  
   hp.ProfileName,  
   co.OrgStructureName,  
   cp.PositionName,  
   cj.JobTitleName,  
   csc.SalaryClassName,  
   est.EnumTranslate AS StatusView,  
   su.UserInfoName AS FirstApproverName,  
   su2.UserInfoName AS MidApproverName,  
   su3.UserInfoName AS NextApproverName,  
   su4.UserInfoName AS LastApproverName,  
   rj1.UserInfoName AS UserRejectName  
 '  
 + @ClauseFromMain  
 + @ClauseWhere +N'   
  
 ORDER BY aad.SortID DESC  
 OFFSET ((@PageIndex - 1) * (@PageSize)) ROWS FETCH NEXT @PageSize ROWS ONLY  
  
 DROP TABLE #tblPermission, #tblEnumStatus  
 IF @Status IS NOT NULL  
  DROP TABLE #StatusFilter  
 IF @ProfileIDs IS NOT NULL  
  DROP TABLE #ProfileFilter  
 IF @strOrgIds IS NOT NULL  
  DROP TABLE #OrgIdFilter  
 '  
DECLARE @Getdata varchar(max)
DECLARE @Query1 varchar(max)
DECLARE @Query2 varchar(max)
DECLARE @Query3 varchar(max)

DECLARE @LeaveDayType NVARCHAR(max) 
SELECT @LeaveDayType = COALESCE(@LeaveDayType+',', '') +'['+ Code +']' FROM Cat_LeaveDayType where IsDelete is null  order by Code asc
--select @LeaveDayType

DECLARE @OverTimeType NVARCHAR(max) 
SELECT @OverTimeType = COALESCE(@OverTimeType+',', '') +'['+ Code +']' FROM Cat_OvertimeType where IsDelete is null order by Code desc
--select @OverTimeType

DECLARE @BusinessTravel NVARCHAR(max) 
SELECT @BusinessTravel = COALESCE(@BusinessTravel+',', '') +'['+ BusinessTravelCode +']' FROM Cat_BusinessTravel where IsDelete is null order by BusinessTravelCode desc
--select @BusinessTravel


SET @Getdata  =' 

DECLARE @DateStart DATETIME, @DateEnd DATETIME
SELECT @DateStart = DateStart , @DateEnd = DateEnd FROM Att_CutOffDuration WHERE ID = @CutOffDurationID

SELECT aad.* 
INTO #Att_AttendanceTable
'+@ClauseFrom
+ @ClauseWhere

 SET @Query1 = '
	SELECT		
				att.ProfileID,clt.Code AS CodeLeaveDay, atti.LeaveDays 
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
	select hwh.ProfileID
	,ISNULL(MH1,0)+ISNULL(DS1,0)+ISNULL(DS2,0)+ISNULL(SIB7,0)+ISNULL(SIB6,0)+ISNULL(SS,0) +ISNULL(NAT,0)+ISNULL(CS3,0)+ISNULL(CS7,0)+ISNULL(SIB4,0)+ISNULL(LS,0)+ISNULL(SM,0)+ISNULL(RA,0)+ISNULL(FP,0)+ISNULL(NP,0)+ISNULL(WP,0)+ISNULL(WP1,0)
	AS NotPaidWorkDayCountP
	,ISNULL(DL,0) as PaidQuitJobDayCount
	,ISNULL(cw.RealWorkDayCount,0) + ISNULL(HLD,0)+ISNULL(A,0)+ISNULL(AN,0)+ISNULL(AN1,0)+ISNULL(ADV,0)+ISNULL(F,0) +ISNULL(M,0)+ISNULL(CM,0)+ISNULL(ML,0)+ISNULL(MLT,0)+ISNULL(C,0) 
	+ ISNULL(BTS2,0)+ISNULL(BTS1,0)+ISNULL(BTOS,0)+ISNULL(BTL,0)+ISNULL(BTOL,0) +ISNULL(WFH,0) as PaidWorkDayCountP
	,ISNULL(cw.RealWorkDayCount,0) as RealWorkDayCount
	,ISNULL(WFH,0) AS WFHCount
	--Phep nam va Ngay nghi cong tac
	,ISNULL(HLD,0) as HLD
	,ISNULL(BTS2,0)+ISNULL(BTS1,0)+ISNULL(BTOS,0)+ISNULL(BTL,0)+ISNULL(BTOL,0) as TongSoNgayCTac,ISNULL(BTS2,0) as DiCTacBTS2,ISNULL(BTS1,0) as DiCTacBTS1,ISNULL(BTOS,0) as DiCTacBTOS,ISNULL(BTL,0) as DiCTacBTL,ISNULL(BTOL,0) as DiCTacBTOL
	---Phep nam
	,ISNULL(AN,0)+ISNULL(AN1,0)+ISNULL(ADV,0) as TongPhepNamP,ISNULL(AN,0) as AN,ISNULL(AN1,0) as AN1,ISNULL(ADV,0) as ADV
	,ISNULL(M,0)+ISNULL(CM,0)+ISNULL(F,0)+ISNULL(ML,0)+ISNULL(MLT,0)+ISNULL(C,0)+ISNULL(A,0) as OtherPaidLeaveP
	,ISNULL(M,0) as M,ISNULL(CM,0) as CM,ISNULL(F,0) as F,ISNULL(ML,0) as ML,ISNULL(MLT,0) as MLT,ISNULL(C,0) as C,NULL as OTC,ISNULL(A,0) as A
	,ISNULL(DL,0) as DL, ISNULL(MH1,0)+ISNULL(DS1,0)+ISNULL(DS2,0)+ISNULL(SIB7,0)+ISNULL(SIB6,0)+ISNULL(SS,0)
	+ISNULL(NAT,0)+ISNULL(CS3,0)+ISNULL(CS7,0)+ISNULL(SIB4,0)+ISNULL(LS,0)+ISNULL(SM,0)+ISNULL(RA,0)+ISNULL(FP,0)+ISNULL(NP,0)+ISNULL(WP,0)+ISNULL(WP1,0) as NghiPhepKoLuongP
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
	--,ISNULL(le.LateInMinutes2,0)/60 as GioDiTreP, ISNULL(le.EarlyOutMinutes2,0) /60 GioVeSomP
	--,NULL as DaysNotInitATT
	,GETDATE() AS DateExport
	--DkLoc
	,NULL AS "cos.OrderNumber",NULL AS "condi.EmploymentType",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation"
	,NULL AS "hp.DateQuit",NULL AS "condi.WorkPlaceID",NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType"
	,NULL AS "condi.EmpStatus",NULL AS "CheckData", NULL AS "ag.GradeAttendanceID"
	INTO #Results
	from #Att_AttendanceTable hwh
	left join #LeaveDayPivot l on hwh.ProfileID = l.ProfileID
	left join #OvertimePivot o on hwh.ProfileID = o.ProfileID
	left join #OvertimePlan op on hwh.ProfileID = op.ProfileID
	left join #BusinessTravelPivot b on hwh.ProfileID = b.ProfileID
	left join #LateEarlyMinutes le on hwh.ProfileID = le.ProfileID
	left join #RealWorkDayCount cw on hwh.ProfileID = cw.ProfileID
	left join #NightShiftHours nsh on hwh.ProfileID = nsh.ProfileID
	'

  
 DECLARE @ParamDefinition NVARCHAR(MAX) = N''  
  + N' @CutOffDurationID uniqueidentifier = NULL,  
    @strOrgIds varchar(max) = NULL,  
    @ProfileIDs VARCHAR(MAX) = NULL,  
    @DateHireFrom datetime = NULL,  
    @DateHireTo datetime = NULL,  
    @DateQuitFrom datetime = NULL,  
    @DateQuitTo datetime = NULL,  
    @Status varchar(max) = NULL,  
    @PageIndex int = NULL,  
    @PageSize int = NULL,  
    @UserName NVARCHAR(50) = NULL,  
    @fieldSort varchar(50) = NULL  
    '  
  
 DECLARE @PrepareQuery NVARCHAR(MAX) = N''  
  + @DefinePermission + CHAR(10)  
  + @DefineEnum + CHAR(10)  
  
 DECLARE @QueryTotalRow NVARCHAR(MAX) = N''  
  + N' DECLARE @TotalRow int = (SELECT COUNT(*) as totalRow' + CHAR(10)  
  + @ClauseFrom + CHAR(10)  
  + @ClauseWhere  
  + N' )'  
  
 DECLARE @SqlQuery NVARCHAR(MAX) = N''  
  + @PrepareQuery + CHAR(10)  
  + @Getdata
  + @Query1 + @Query2 + @Query3
  + @QueryTotalRow
  + @ClauseSelect  
 PRINT @ParamDefinition  
  
 DECLARE @SqlPrint AS NVARCHAR(max) = @SqlQuery;  
 WHILE LEN(@SqlPrint) > 2000  
 BEGIN  
  PRINT(SUBSTRING(@SqlPrint, 0, 2000))  
  SET @SqlPrint = SUBSTRING(@SqlPrint, 2000, LEN(@SqlPrint));  
 END  
 print @SqlPrint  
 

 EXEC SP_EXECUTESQL @SqlQuery, @ParamDefinition,  
  @CutOffDurationID,  
  @strOrgIds,  
  @ProfileIDs,  
  @DateHireFrom,  
  @DateHireTo,  
  @DateQuitFrom,  
  @DateQuitTo,  
  @Status,  
  @PageIndex,  
  @PageSize,  
  @UserName,  
  @fieldSort  
END
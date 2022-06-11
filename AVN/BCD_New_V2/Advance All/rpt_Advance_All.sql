---Nam Ta: 18/8/2021: Bang tam ung luong All: Bang tam ung, DS khong nhan tam ung, Bang Tam ung Ngan Hang
ALTER proc rpt_Advance_All	
@condition nvarchar(max) = " and (MonthYear = '2022-02-01') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'khang.nguyen'
as
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
END;

----Condition----
DECLARE @MonthYearCondition VARCHAR(100) = ' '
DECLARE @PayPaidType nvarchar(200) = ''
DECLARE @AmountCondition varchar(500) = ''
DECLARE @IsAdvance VARCHAR(500) =' '
DECLARE @IsNotAdvance VARCHAR(500) =' '
DECLARE @IsAdvanceBanking VARCHAR(500) =' '
DECLARE @CheckData VARCHAR(1000) =''

-- cat dieu kien
set @str = REPLACE(@condition,',','@')
SET @str = REPLACE(@str,'and (',',')
SELECT ID INTO #tableTempCondition FROM SPLIT_To_NVARCHAR (@str)
SET @row = (SELECT COUNT(ID) FROM SPLIT_To_NVARCHAR (@str))
SET @countrow = 0
SET @index = 0

WHILE @row > 0
BEGIN
	SET @index = 0
	SET @ID = (SELECT TOP 1 ID FROM #tableTempCondition)
	SET @tempID = REPLACE(@ID,'@',',')

	SET @index = 0
	SET @index = CHARINDEX('MonthYear = ',@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @TempCondition = 'and ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
		SET @MonthYearCondition = @TempCondition
	END

	SET @index = CHARINDEX('(GroupBank ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @condition = REPLACE(@condition,'(Groupbank ','(cb.Groupbank ')
	END

	SET @index = CHARINDEX('(BankName ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @condition = REPLACE(@condition,'(BankName ','(cb.BankName ')
	END

	SET @index = CHARINDEX('(ProfileName ','('+@tempID,0) 
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
			
	SET @index = CHARINDEX('(condi.EmpStatus ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.EmpStatus ','(sup.EmpStatus ')
	END


	SET @index = CHARINDEX('(PayPaidType ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @TempCondition = 'AND ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
		SET @PayPaidType = @TempCondition
	END

	SET @index = CHARINDEX('(AmountCondition ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @TempCondition = 'and ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
		SET @AmountCondition = REPLACE(@TempCondition,'(AmountCondition in ','')
		SET @AmountCondition = REPLACE(@AmountCondition,',',' OR ')
		SET @AmountCondition = REPLACE(@AmountCondition,'))',')')
	END

	SET @index = CHARINDEX('(IsAdvance ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @TempCondition = 'AND ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
		SET @IsAdvance = @TempCondition
		SET @IsAdvance = REPLACE(@IsAdvance,' ','') 
	END

	SET @index = CHARINDEX('(IsNotAdvance ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @TempCondition = 'AND ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
		SET @IsNotAdvance = @TempCondition
		SET @IsNotAdvance = REPLACE(@TempCondition,' ','') 
	END

	SET @index = CHARINDEX('(IsAdvanceBanking ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @TempCondition = 'AND ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
		SET @IsAdvanceBanking = @TempCondition
		SET @IsAdvanceBanking = REPLACE(@IsAdvanceBanking,' ','') 
	END

	DELETE #tableTempCondition WHERE ID = @ID
	SET @row = @row - 1

END
DROP TABLE #tableTempCondition

--- Giá trị
IF (@AmountCondition IS NOT NULL AND @AmountCondition <> '')
BEGIN
	SET @index = CHARINDEX('E_EqualToZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_EqualToZero''','AdvanceAmount = 0')
	END
	SET @index = CHARINDEX('E_LessThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_LessThanZero''','AdvanceAmount < 0')
	END
	SET @index = CHARINDEX('E_GreaterThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_GreaterThanZero''','AdvanceAmount > 0')	
	END
END

-- Hình thức thanh toán
IF (@PayPaidType IS NOT NULL AND @PayPaidType <> '')
BEGIN
	SET @index = CHARINDEX('Cash',@PayPaidType,0) 
	IF(@index > 0)
	BEGIN
	SET @PayPaidType = REPLACE(@PayPaidType,'Cash',N'Tiền mặt')
	END
	SET @index = CHARINDEX('Transfer',@PayPaidType,0) 
	IF(@index > 0)
	BEGIN
	SET @PayPaidType = REPLACE(@PayPaidType,'Transfer',N'Chuyển khoản')
	END
END

IF CHARINDEX(N'Chuyển khoản%',@PayPaidType,0) >0
BEGIN
SET @PayPaidType = REPLACE(@PayPaidType,N'Chuyển khoản%'')',N'Chuyển khoản%'' OR PayPaidType like ''HRM_DynLang_Salary_Transfer'')')
END

IF CHARINDEX('IsAdvance=1',@IsAdvance,0) > 0
BEGIN
SET @CheckData += ' AND UnusualPayID IS NOT NULL'
END
IF CHARINDEX('IsNotAdvance=1',@IsNotAdvance,0) > 0
BEGIN
IF LEN(@CheckData) > 2
BEGIN
SET @CheckData += ' OR ( AdvanceAmount = 0 OR UnusualPayID IS NULL) '
END
ELSE
SET @CheckData += ' AND ( AdvanceAmount = 0 OR UnusualPayID IS NULL ) '
END
IF CHARINDEX('IsAdvanceBanking=1',@IsAdvanceBanking,0) > 0
BEGIN
IF LEN(@CheckData) > 2
BEGIN
SET @CheckData += ' OR (UnusualPayID IS NOT NULL AND AccountNo IS NOT NULL) '
END
ELSE
SET @CheckData += ' AND (UnusualPayID IS NOT NULL AND AccountNo IS NOT NULL ) '
END

--IF @CheckData = ''
--BEGIN
--SET @CheckData =' AND (DateQuit IS NULL OR DateQuit > @DateEndAdvance)  '
--END

--- Pivot Leaveday
DECLARE @LeaveDayTypePivot NVARCHAR(MAX) 
SELECT @LeaveDayTypePivot = COALESCE(@LeaveDayTypePivot+',', '') +'[DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_'+ Code +'_BYUNUSUALPAY]' FROM Cat_LeaveDayType WHERE IsDelete IS NULL  AND PaidRate = 0  ORDER BY Code ASC

----- Select leaveDay
--DECLARE @LeaveDayType NVARCHAR(max) 
--SELECT @LeaveDayType = COALESCE(@LeaveDayType+',', '') +'''DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_'+ Code +'_BYUNUSUALPAY''' FROM Cat_LeaveDayType where IsDelete is NULL  AND PaidRate = 0  order by Code ASC
--SET @LeaveDayType = ' supi.Code IN (' + @LeaveDayType + ' )'

--- Select leaveDay
DECLARE @LeaveDayType NVARCHAR(MAX) 
SELECT @LeaveDayType = COALESCE(@LeaveDayType+',', '') +'DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_'+ Code +'_BYUNUSUALPAY' FROM Cat_LeaveDayType WHERE IsDelete IS NULL  AND PaidRate = 0  ORDER BY Code ASC
SET @LeaveDayType = ' supi.Code IN ( SELECT ID FROM SPLIT_To_NVARCHAR (''' + @LeaveDayType + ''' ) )'

---Case when cho ra ly do khong nhan ung
DECLARE @CaseWhen NVARCHAR(MAX)
SELECT @CaseWhen = COALESCE(@CaseWhen+'+', '') +' CASE WHEN [DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_'+ Code +'_BYUNUSUALPAY] > 0 THEN ''' +' | ' 
+Code + ': '+ ''' ' +'+ CONVERT(NVARCHAR(10), [DYN38_ATTI_SUMLEAVEHOURS_DAYKEEP_UNUSUALPAY_'+ Code +'_BYUNUSUALPAY]) ELSE '''' END'

FROM Cat_LeaveDayType WHERE IsDelete IS NULL  AND PaidRate = 0  ORDER BY Code ASC


-- Export

DECLARE @getdata VARCHAR(MAX)
DECLARE @CountLeaveDay VARCHAR(MAX)
DECLARE @query VARCHAR(MAX)
DECLARE @query2 NVARCHAR(MAX)
DECLARE @queryPageSize VARCHAR(MAX)





SET @getdata = '
			
	CREATE TABLE #tblPermission (id uniqueidentifier primary key )
	INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'

	--------------------------------Lay bang luong chinh-------------------------------------
	select s.* into #Sal_UnusualPay from Sal_UnusualPay s join #tblPermission tb on s.ProfileID = tb.ID
	where isdelete is null '+@MonthYearCondition+'
	print(''#Sal_UnusualPay'')

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

	--- Lay ngay bat dau va ket thuc ky luong
	DECLARE @DateStart DATETIME, @DateEnd DATETIME, @StartMonth  DATETIME
	SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYearCondition+'

	---Ngay ket thuc ky ung
	DECLARE @UnusualDay INT
	DECLARE @DateEndAdvance DATETIME

	SELECT @UnusualDay = value1 from Sys_AllSetting where isdelete is null and Name like ''%AL_Unusualpay_DaykeepUnusualpay%''
	SET @DateEndAdvance = DATEADD(DAY,@UnusualDay -1,@StartMonth)

	DECLARE @OrtherGroupBank Nvarchar(200)
	SET @OrtherGroupBank = ( SELECT DISTINCT BankName FROM dbo.Cat_Bank WHERE BankCode = ''VIETCOMBANK'' AND IsDelete IS NULL )

	-- Lay du lieu qtct moi nhat trong thang
	if object_id(''tempdb..#Hre_WorkHistory'') is not null 
		drop table #Hre_WorkHistory;

	;WITH WorkHistory AS
	(
	select		' +@Top+ ' 
				*,ROW_NUMBER() OVER(PARTITION BY hwh.ProfileID ORDER BY hwh.DateEffective DESC) AS rk
	from		Hre_WorkHistory as hwh
	WHERE		hwh.IsDelete is null
				AND	hwh.DateEffective <= @DateEndAdvance
				AND	hwh.Status = ''E_APPROVED''
	) 
	SELECT	*
	INTO	#Hre_WorkHistory
	FROM	WorkHistory 
	WHERE	rk = 1
	print(''#Hre_WorkHistory'');

'
SET @CountLeaveDay = '
	SELECT * 
	INTO #LeaveDayPivot
	FROM 
	(
	SELECT		' +@Top+ '
				sup.ProfileID,CAST(supi.Amount AS FLOAT) AS Amount,supi.Code
	FROM		#Sal_UnusualPay sup
	LEFT JOIN	dbo.Sal_UnusualPayItem supi
		ON		supi.UnusualPayID = sup.ID
	WHERE		'+@LeaveDayType+'
	) A
	PIVOT ( SUM(Amount) FOR Code IN ([LeavedayTypeList])) P

	SELECT	ProfileID,[CaseWhenLeave] AS ReasonLeave
	INTO	#CountLeaveDay
	FROM	#LeaveDayPivot

	UPDATE	#CountLeaveDay
	SET		ReasonLeave = substring(ReasonLeave,charindex(''|'',ReasonLeave)+2, len(ReasonLeave))
	'

SET @CountLeaveDay = REPLACE(@CountLeaveDay,'[LeavedayTypeList]',@LeaveDayTypePivot)
SET @CountLeaveDay = REPLACE(@CountLeaveDay,'[CaseWhenLeave]',@CaseWhen)


SET @query=
'	
	-----------------------Lay du lieu tu bang Luong---------------------------
	;WITH Sal_UnusualPay_New AS
	(
	select		' +@Top+ '
				hp.ID as ProfileID , hp.CodeEmp, hp.ProfileName
				,ISNULL(neorg.DivisionName,'' '') AS DivisionName ,ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
				,csct.SalaryClassName, cptl.PositionName, cjttl.JobTitleName,ISNULL(cetl.EN,'' '') AS EmploymentType,cetl2.EN AS LaborType,cnet.NameEntityName AS EmployeeGroupName, cwptl.WorkPlaceName, hp.DateHire, hp.DateQuit
				,cetl3.VN AS EmpStatus,sup.MonthYear,ISNULL(sup.Amount,0) AS AdvanceAmount
				,CASE WHEN sup.Amount > 0 THEN NULL ELSE
					CASE WHEN hpmi.IsRetire = 1 THEN N'' + Not receiving advance salary '' ELSE '''' END +
					CASE WHEN hp.DateQuit IS NOT NULL AND hp.DateQuit <= @DateEnd AND hp.DateQuit >= @DateStart THEN N'' + Resigned employee: '' + CONVERT(NVARCHAR(30), hp.DateQuit,103) +'' '' ELSE '''' END +
					CASE WHEN hp.DateHire <= @DateEndAdvance AND hp.DateHire >= @DateStart THEN N'' + New employee, the number days of not starting work: '' + CONVERT(Varchar(10), dbo.fnc_NumberOfExceptWeekends(@DateStart,hp.DateHire)) + '' '' ELSE '''' END +
					CASE WHEN cld.ReasonLeave <>'''' THEN '' + The unpaid leave days: '' +''"''+ cld.ReasonLeave + ''"'' + '' '' ELSE '''' END +
					CASE WHEN sup.ID IS NULL THEN N'' + Absence in advance sheet'' ELSE '''' END +
					CASE WHEN CAST(supi3.Amount AS FLOAT) + CAST(supi35.Amount AS FLOAT) + CAST(supi36.Amount AS FLOAT) + CAST(supi37.Amount AS FLOAT) + CAST(supi38.Amount AS FLOAT) + CAST(supi39.Amount AS FLOAT) + CAST(supi40.Amount AS FLOAT) = 0 
						THEN N'' + Having no paid day'' ELSE '''' END
					END AS ReasonOfADVANCE
				,supi.Amount AS PayPaidType
				,cb.GroupBank,sup.AccountNo,ssim.AccountName AS AccountName, cb.BankName,supi2.Amount AS BranchName,cb.BankName + '', '' + ISNULL(supi2.Amount,'''') AS BankBranchName
				,CASE WHEN cb.GroupBank IN(''VIETINBANK'', ''BIDV'', ''VCB'',''AGRIBANK'') THEN ISNULL(cb.BankName,''NULL'') ELSE @OrtherGroupBank END AS GroupBankName
				,ISNULL(neorg.DivisionOrder,-881507) AS DivisionOrder, ISNULL(neorg.CenterOrder,-771507) AS CenterOrder , ISNULL(neorg.DepartmentOrder,-661507) AS DepartmentOrder ,ISNULL(neorg.SectionOrder,-551507) AS SectionOrder
				,ISNULL(neorg.UnitOrder,-441507) AS UnitOrder,ISNULL(cetl.EN,''NULL'') AS EmploymentTypeGroup
				,sup.ID as UnusualPayID
	FROM		Hre_Profile hp 
	LEFT JOIN	#Sal_UnusualPay sup
		ON		hp.id= sup.ProfileID
	LEFT JOIN	#Hre_WorkHistory hwh 
		ON		hp.ID = hwh.ProfileID 
	LEFT JOIN	Cat_OrgStructure cos 
		ON		cos.ID = hwh.OrganizationStructureID
	LEFT JOIN	#NameEnglishORG neorg 
		ON		neorg.OrgStructureID = hwh.OrganizationStructureID
	LEFT JOIN	Cat_bank cb
		ON		cb.ID = sup.BankID
	LEFT JOIN	Cat_SalaryClass csc
		ON		csc.ID = hwh.SalaryClassID
	LEFT JOIN	Cat_SalaryClass_Translate csct
		ON		csct.OriginID = hwh.SalaryClassID
	LEFT JOIN	Cat_Position_Translate cptl
		ON		cptl.OriginID = hwh.PositionID
	LEFT JOIN	Cat_JobTitle_Translate cjttl
		ON		cjttl.OriginID = hwh.JobTitleID
	LEFT JOIN	Cat_WorkPlace_Translate cwptl
		ON		cwptl.OriginID = hwh.WorkPlaceID
	LEFT JOIN	Cat_NameEntity_Translate cnet
		ON		cnet.OriginID = hwh.EmployeeGroupID
	LEFT JOIN	#CountLeaveDay cld
		ON		cld.ProfileID = hp.ID
	LEFT JOIN	Sal_UnusualPayItem supi
		ON		supi.UnusualPayID = sup.ID 
				AND supi.Code = ''SAL_SALARYINFORMATION_ISCASH_BYUNUSUALPAY'' AND supi.Isdelete IS NULL
	LEFT JOIN	Sal_UnusualPayItem supi2
		ON		supi2.UnusualPayID = sup.ID 
				AND supi2.Code = ''SAL_SALARYINFORMATION_BRANCHNAME1'' AND supi2.Isdelete IS NULL
	LEFT JOIN	Sal_UnusualPayItem supi3
		ON		supi3.UnusualPayID = sup.ID 
				AND supi3.Code = ''ATTI_SUM_TOTAL_LEAVE_PAIDDAY_BYUNUSUALPAY'' AND supi3.Isdelete IS NULL
	LEFT JOIN	Sal_UnusualPayItem supi35 on sup.ID = supi35.UnusualPayID and supi35.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_BTOL''
	LEFT JOIN	Sal_UnusualPayItem supi36 on sup.ID = supi36.UnusualPayID and supi36.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_BTOS''
	LEFT JOIN	Sal_UnusualPayItem supi37 on sup.ID = supi37.UnusualPayID and supi37.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_BTL''
	LEFT JOIN	Sal_UnusualPayItem supi38 on sup.ID = supi38.UnusualPayID and supi38.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_BTS1''
	LEFT JOIN	Sal_UnusualPayItem supi39 on sup.ID = supi39.UnusualPayID and supi39.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_BTS2''
	LEFT JOIN	Sal_UnusualPayItem supi40 on sup.ID = supi40.UnusualPayID and supi40.code = ''ATT_ATTENDANCETABLEITEM_SUM_BUSSINESSTRAVELHOURS_BYUNUSUALPAY_WFH''
	LEFT JOIN	Hre_ProfileMoreInfo hpmi
		ON		hpmi.ID = hp.ProfileMoreInfoID
	LEFT JOIN	Sal_SalaryInformation ssim
	ON		ssim.ProfileID = sup.ProfileID AND ssim.BankID = sup.BankID AND ssim.AccountNo = sup.AccountNo AND ssim.IsDelete IS NULL

'
SET @query2=
'	
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
				WHERE	cetl.EnumKey = sup.EmpStatus 
						AND cetl.EnumKey in (''E_PROFILE_ACTIVE'',''E_PROFILE_QUIT'',''E_PROFILE_NEW'') AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl3

	CROSS APPLY (
				SELECT	TOP(1) ProfileID
				FROM	Sal_Grade sg
				WHERE	sg.ProfileID = hp.ID 
						AND sg.MonthStart <= @DateEndAdvance AND ( sg.MonthEnd IS NULL OR sg.MonthEnd >= @DateStart )
						AND sg.Isdelete IS NULL
				ORDER BY sg.DateUpdate DESC
				) cetl4

	WHERE		hp.IsDelete is null
		AND		hp.DateHire <= @DateEndAdvance
		AND		(hp.DateQuit IS NULL OR hp.DateQuit > @DateEndAdvance)
		AND		exists (Select * from #tblPermission tpm where id = hp.id )
		'+ISNULL(@condition,'')+'
	)
	Select *  
	into #Sal_UnusualPay_New
	from Sal_UnusualPay_New 
	where 1 = 1
	'+ISNULL(@PayPaidType,'')+ '  
	'+ISNULL(@CheckData,'')+ '  
	'+ISNULL(@AmountCondition,'')+'
	print(''#Sal_UnusualPay_New'');

	SELECT		*
				'+CASE WHEN @IsAdvanceBanking = 'AND(IsAdvanceBanking=1)' 
				THEN ',ROW_NUMBER() OVER (ORDER BY GroupBankName,BankName,BranchName, DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp) as RowNumber' 
				ELSE ',ROW_NUMBER() OVER (ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as RowNumber' END+'
				,GETDATE() AS DateExport
				,NULL AS "cos.OrderNumber",NULL AS "condi.EmploymentType",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit"
				,NULL AS "condi.WorkPlaceID",NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType", NULL AS "AmountCondition"	
				,NULL AS "condi.EmpStatus",NULL AS "IsAdvance", NULL AS "IsNotAdvance", NULL AS "IsAdvanceBanking"
	INTO		#Results
	FROM		#Sal_UnusualPay_New
	'
set @queryPageSize = ' 
	ALTER TABLE #Results ADD TotalRow int
	declare @totalRow int
	SELECT @totalRow = COUNT(*) FROM #Results
	update #Results set TotalRow = @totalRow

	SELECT		RowNumber AS STT,*
	FROM		#Results 
	WHERE		RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
	ORDER BY	RowNumber

	DROP TABLE #Results
	drop table #tblPermission, #Hre_WorkHistory
	drop table #Sal_UnusualPay,#Sal_UnusualPay_New,#CountLeaveDay
	DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG
	DROP TABLE #LeaveDayPivot
	'

print (@getdata)
print (@CountLeaveDay)
print (@query)
print (@query2)
print (@queryPageSize)
	

exec( @getdata +@CountLeaveDay+@query +@query2 + @queryPageSize )


END
--rpt_Advance_All


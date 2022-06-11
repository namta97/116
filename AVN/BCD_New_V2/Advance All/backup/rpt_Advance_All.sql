---Nam Ta: 18/8/2021: BC Luong All: Bang tam ung, DS khong nhan tam ung, Bang Tam ung Ngan Hang
ALTER proc rpt_Advance_All	
--@condition nvarchar(max) = " and (MonthYear = '2021-04-01') and (IsAdvance = 1 ) ",
@condition nvarchar(max) = " and (MonthYear = '2021-04-01') and (IsNotAdvance = 1 ) ",
--@condition nvarchar(max) = " and (MonthYear = '2021-04-01')  ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'khang.nguyen'
as
BEGIN

IF @condition = ' ' 
begin
set @condition =  ' and (MonthYear = ''2021-04-01'') '
END

declare @IsExport bit
if (@condition is null or @condition = '')
set @IsExport = 0

declare @str nvarchar(max)
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
declare @tempID nvarchar(Max)
declare @tempCodition nvarchar(Max)
declare @conditionCutOffDurationID varchar(100)
set @conditionCutOffDurationID = ''
DECLARE @MonthYear nvarchar(50) = ' '
DECLARE @MonthYearSP nvarchar(50) = ' '
DECLARE @PayPaidType nvarchar(200) = ''
DECLARE @AmountCondittion nvarchar(500) = ''
DECLARE @IsAdvance NVARCHAR(500) =' '
DECLARE @IsNotAdvance NVARCHAR(500) =' '
DECLARE @IsAdvanceBanking NVARCHAR(500) =' '
DECLARE @CheckData NVARCHAR(1000) =''
-- cat dieu kien

while @row > 0
begin
	set @index = 0
	set @ID = (select top 1 ID from #tableTempCondition)
	set @tempID = replace(@ID,'@',',')

	set @index = 0
	set @index = charindex('MonthYear = ',@tempID,0) 
	if(@index > 0)
	begin
		--set @condition = REPLACE(@condition,'(MonthYear = ','(sup.MonthYear = ')
		set @tempCodition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@tempCodition,'')
		set @MonthYear = @tempCodition
		SET @MonthYearSP = REPLACE(@tempCodition,'''','''''')
	end

	set @index = charindex('(GroupBank ','('+@tempID,0) 
	if(@index > 0)
	begin
		set @condition = REPLACE(@condition,'(Groupbank ','(cb.Groupbank ')
	end

	set @index = charindex('(BankName ','('+@tempID,0) 
	if(@index > 0)
	begin
		set @condition = REPLACE(@condition,'(BankName ','(cb.BankName ')
	END

	set @index = charindex('(ProfileName ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
	END

	set @index = charindex('(PayPaidType ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCodition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@tempCodition,'')
		set @PayPaidType = @tempCodition
	END

	SET @index = charindex('(AmountCondittion ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCodition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@tempCodition,'')
		set @AmountCondittion = REPLACE(@tempCodition,'(AmountCondittion in ','')
		set @AmountCondittion = REPLACE(@AmountCondittion,',',' OR ')
		set @AmountCondittion = REPLACE(@AmountCondittion,'))',')')
	END

	set @index = charindex('(IsAdvance ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCodition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@tempCodition,'')
		set @IsAdvance = @tempCodition
		set @IsAdvance = REPLACE(@IsAdvance,' ','') 
	END

	set @index = charindex('(IsNotAdvance ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCodition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@tempCodition,'')
		set @IsNotAdvance = @tempCodition
		set @IsNotAdvance = REPLACE(@tempCodition,' ','') 
	END

	set @index = charindex('(IsAdvanceBanking ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCodition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@tempCodition,'')
		set @IsAdvanceBanking = @tempCodition
		set @IsAdvanceBanking = REPLACE(@IsAdvanceBanking,' ','') 
	END

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1

END


--- Giá trị
IF (@AmountCondittion is not null and @AmountCondittion != '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCondittion,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondittion = REPLACE(@AmountCondittion,'''E_EqualToZero''','Amount = 0')
	END
	SET @index = charindex('E_LessThanZero',@AmountCondittion,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondittion = REPLACE(@AmountCondittion,'''E_LessThanZero''','Amount < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondittion,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondittion = REPLACE(@AmountCondittion,'''E_GreaterThanZero''','Amount > 0')	
	END
END

-- Hình thức thanh toán
IF (@PayPaidType is not null AND @PayPaidType != '')
BEGIN
	SET @index = charindex('Cash',@PayPaidType,0) 
	IF(@index > 0)
	BEGIN
	SET @PayPaidType = REPLACE(@PayPaidType,'Cash',N'Tiền mặt')
	END
	SET @index = charindex('Transfer',@PayPaidType,0) 
	IF(@index > 0)
	BEGIN
	SET @PayPaidType = REPLACE(@PayPaidType,'Transfer',N'Chuyển khoản')
	END
END


IF CHARINDEX('IsAdvance=1',@IsAdvance,0) > 0
BEGIN
SET @CheckData += ' AND UnusualPayID IS NOT NULL '
END
IF CHARINDEX('IsNotAdvance=1',@IsNotAdvance,0) > 0
BEGIN
IF LEN(@CheckData) > 2
BEGIN
SET @CheckData += ' OR ( Amount = 0 OR UnusualPayID IS NULL ) '
END
ELSE
SET @CheckData += ' AND ( Amount = 0 OR UnusualPayID IS NULL ) '
END
IF CHARINDEX('IsAdvanceBanking=1',@IsAdvanceBanking,0) > 0
BEGIN
IF LEN(@CheckData) > 2
BEGIN
SET @CheckData += ' OR ( Amount > 0 AND UnusualPayID IS NOT NULL AND AccountNo IS NOT NULL ) '
END
ELSE
SET @CheckData += ' AND ( Amount > 0 AND UnusualPayID IS NOT NULL AND AccountNo IS NOT NULL ) '
END

IF @CheckData = ''
BEGIN
SET @CheckData =' AND UnusualPayID IS NOT NULL '
END 

-- Export

declare @getdata nvarchar(max)
declare @query nvarchar(max)
declare @queryPageSize nvarchar(max)
DECLARE @InsertTable NVARCHAR(max)
SET @InsertTable = '
CREATE TABLE #CountLeaveDay ( ProfileID uniqueidentifier primary key, ReasonLeave NVARCHAR(100))
INSERT INTO #CountLeaveDay EXEC Countleaveday_EachEmployee '''+@MonthYearSP+''',1
'
set @getdata = '
			
		CREATE TABLE #tblPermission (id uniqueidentifier primary key )
		INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'

		--------------------------------Lay bang luong chinh-------------------------------------
		select s.* into #Sal_UnusualPay from Sal_UnusualPay s join #tblPermission tb on s.ProfileID = tb.ID
		where isdelete is null '+@MonthYear+'
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
		SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYear+'

		---Ngay ket thuc ky ung
		DECLARE @UnusualDay INT
		DECLARE @DateEndAdvance DATETIME

		SELECT @UnusualDay = value1 from Sys_AllSetting where isdelete is null and Name like ''%AL_Unusualpay_DaykeepUnusualpay%''
		SET @DateEndAdvance = DATEADD(DAY,@UnusualDay -1,@StartMonth)

		DECLARE @OrtherGroupBank Nvarchar(200)
		SET @OrtherGroupBank = ( SELECT DISTINCT BankName FROM dbo.Cat_Bank WHERE GroupBank = ''VCB'' AND IsDelete IS NULL )
'
SET @query=
'	
		-----------------------Lay du lieu tu bang Luong---------------------------
		;WITH Sal_UnusualPay_New AS
		(
		select 
					hp.ID as ProfileID , hp.CodeEmp, hp.ProfileName, hp.NameEnglish
					,ISNULL(neorg.DivisionName,'' '') AS DivisionName ,ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
					,csct.SalaryClassName, cptl.PositionName, cjttl.JobTitleName,ISNULL(cetl.EN,'' '') AS EmploymentType, cwptl.WorkPlaceName AS WorkPlaceName, hp.DateHire, hp.DateQuit
					,CASE WHEN hpmi.IsRetire = 1 THEN N'' + Not receiving advance salary '' ELSE '''' END +
						CASE WHEN hp.DateQuit IS NOT NULL AND hp.DateQuit <= @DateEndAdvance AND hp.DateQuit >= @DateStart THEN N'' + Resignation employee: '' + CONVERT(NVARCHAR(30), hp.DateQuit,103) +'' '' ELSE '''' END +
						CASE WHEN hp.DateHire <= @DateEndAdvance AND hp.DateHire >= @DateStart THEN N'' + New employee, the number days of not starting work: '' + CONVERT(Varchar(10), dbo.fnc_NumberOfExceptWeekends(@DateStart,hp.DateHire)) + '' '' ELSE '''' END +
						CASE WHEN cld.ReasonLeave <>'''' THEN '' + The unpaid leave days: '' +''"''+ cld.ReasonLeave + ''"'' + '' '' ELSE '''' END +
						CASE WHEN sup.ID IS NULL THEN N'' + Absence in advance sheet'' ELSE '''' 
						END AS ReasonOfADVANCE
					,sup.Amount,sup.AccountNo,cb.BankName + '', '' + ISNULL(supi2.Amount,'''') AS BankBranhName, cb.BankName,supi2.Amount AS BranhName, cb.GroupBank,CASE WHEN cb.GroupBank IN(''ICB'', ''BIDV'', ''VCB'',''NN'') THEN ISNULL(cb.BankName,''NULL'') ELSE @OrtherGroupBank END AS GroupBankName
					,supi.Amount AS PayPaidType,sup.ID as UnusualPayID
					,ISNULL(neorg.DivisionOrder,881507) AS DivisionOrder, ISNULL(neorg.CenterOrder,771507) AS CenterOrder , ISNULL(neorg.DepartmentOrder,661507) AS DepartmentOrder ,ISNULL(neorg.SectionOrder,551507) AS SectionOrder,ISNULL(neorg.UnitOrder,441507) AS UnitOrder,ISNULL(cetl.EN,'' '') AS EmploymentTypeGroup
					,sup.MonthYear,ROW_NUMBER() OVER(PARTITION BY hwh.ProfileID ORDER BY hwh.DateEffective DESC) AS rk
		FROM		Hre_Profile hp 
		LEFT JOIN	#Sal_UnusualPay sup
			ON		hp.id= sup.ProfileID
		LEFT JOIN	Hre_WorkHistory hwh 
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
		LEFT JOIN	#CountLeaveDay cld
			ON		cld.ProfileID = hp.ID
		LEFT JOIN	Sal_UnusualPayItem supi
			ON		supi.UnusualPayID = sup.ID 
					AND supi.Code = ''SAL_SALARYINFORMATION_ISCASH_BYUNUSUALPAY'' AND supi.Isdelete IS NULL
		LEFT JOIN	Sal_UnusualPayItem supi2
			ON		supi2.UnusualPayID = sup.ID 
					AND supi2.Code = ''SAL_SALARYINFORMATION_BRANCHNAME1'' AND supi2.Isdelete IS NULL
		LEFT JOIN	Hre_ProfileMoreInfo hpmi
			ON		hpmi.ID = hp.ProfileMoreInfoID
		OUTER APPLY (
					SELECT	TOP(1) cetl.EN, cetl.VN
					FROM	Cat_EnumTranslate cetl
					WHERE	cetl.EnumKey = hwh.EmploymentType 
							AND cetl.EnumName = ''EmploymentType'' AND cetl.IsDelete is null
					ORDER BY DateUpdate DESC
					) cetl
		WHERE		hwh.IsDelete is null
			AND		hwh.DateEffective <= @DateEndAdvance
			AND		hwh.Status = ''E_APPROVED''
			AND		hp.IsDelete is null
			AND		hp.DateHire <= @DateEndAdvance
			AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart )
			'+ISNULL(@condition,'')+'
		)

		Select *  
		into #Sal_UnusualPay_New
		from Sal_UnusualPay_New 
		where rk = 1
		'+ISNULL(@PayPaidType,'')+ '  
		'+ISNULL(@CheckData,'')+ '  
		'+ISNULL(@AmountCondittion,'')+'
		print(''#Sal_UnusualPay_New'');

		SELECT		*
					'+CASE WHEN @IsAdvanceBanking = 'AND(IsAdvanceBanking=1)' THEN ',ROW_NUMBER() OVER (ORDER BY GroupBankName,BankName,BranhName,BankBranhName) as RowNumber' 
					ELSE ',ROW_NUMBER() OVER ( ORDER BY DivisionName,DivisionOrder, CenterName,CenterOrder,DepartmentName,DepartmentOrder, SectionName,SectionOrder ,EmploymentType ,ProfileName ) as RowNumber' END+'
					,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "hwh.EmploymentType",NULL AS "hwh.SalaryClassID" ,NULL AS "hwh.PositionID", NULL AS "hwh.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "hwh.WorkPlaceID"
					,NULL AS "hwh.EmployeeGroupID", NULL AS "hwh.LaborType", NULL AS "hwh.CostCentreID", NULL AS "csc.AbilityTitleID", NULL AS "AmountCondittion"
					,NULL AS "sup.EmpStatus",NULL AS "IsAdvance", NULL AS "IsNotAdvance", NULL AS "IsAdvanceBanking"
		INTO		#Results
		FROM		#Sal_UnusualPay_New
		'
set @queryPageSize = ' 
		ALTER TABLE #Results ADD TotalRow int
		declare @totalRow int
		SELECT @totalRow = COUNT(*) FROM #Results
		update #Results set TotalRow = @totalRow

		SELECT *, GETDATE() AS DateExport
		FROM #Results 
		WHERE RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
		ORDER BY RowNumber

		DROP TABLE #Results
		drop table #tblPermission
		drop table #Sal_UnusualPay_New
		DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG

		'
	--print (@InsertTable)
	--print (@getdata)
	--print (@query)
	--print (@queryPageSize)
	

	exec(@InsertTable + @getdata +@query + @queryPageSize )


END
--rpt_Advance_All


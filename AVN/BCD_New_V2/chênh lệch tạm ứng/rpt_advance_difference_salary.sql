---Nam Ta: 02/8/2021: Chenh lech tam ung
ALTER proc rpt_advance_difference_salary
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
DECLARE @CurrentEnd bigint
DECLARE @Offset TINYINT

if ltrim(rtrim(@Condition)) = '' OR @Condition is null
	begin
			set @Top = ' top 0 ';
			SET @condition =  ' and (MonthYear = ''2022-02-01'') '
	end;


-- Condition
DECLARE @MonthYear nvarchar(50) = ' '
DECLARE @AmountCondition nvarchar(100) = ''
DECLARE @PayPaidType nvarchar(100) = ''

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

	set @index = 0
	set @index = charindex('MonthYear = ',@tempID,0) 
	if(@index > 0)
	begin
		set @condition = REPLACE(@condition,'(MonthYear = ','(sup.MonthYear = ')
		set @TempCondition = 'and ('+@tempID
		SET @MonthYear = @TempCondition
	END

	set @index = charindex('(ProfileName ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
	end

	SET @index = CHARINDEX('(CodeEmp ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(CodeEmp ','(hp.CodeEmp ')
	END

	set @index = charindex('(condi.EmploymentType ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.EmploymentType ','(spt.EmploymentType ')
	END
    
	set @index = charindex('(condi.SalaryClassID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.SalaryClassID ','(spt.SalaryClassID ')
	END

	set @index = charindex('(condi.PositionID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.PositionID ','(spt.PositionID ')
	END
	
	set @index = charindex('(condi.JobTitleID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.JobTitleID ','(spt.JobTitleID ')
	END
	
	set @index = charindex('(condi.WorkPlaceID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.WorkPlaceID ','(spt.WorkPlaceID ')
	END
	
	set @index = charindex('(condi.EmployeeGroupID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.EmployeeGroupID ','(spt.EmployeeGroupID ')
	END
		
	set @index = charindex('(condi.LaborType ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.LaborType ','(spt.LaborType ')
	END
			
	set @index = charindex('(condi.EmpStatus ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.EmpStatus ','(spt.EmpStatus ')
	END
			
	set @index = charindex('(condi.CostCentreID ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(condi.CostCentreID ','(spt.CostCentreID ')
	END

	set @index = charindex('(PayPaidType ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @PayPaidType = @TempCondition
	END

	set @index = charindex('(AmountCondition ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @AmountCondition = REPLACE(@TempCondition,'(AmountCondition in ','')
		set @AmountCondition = REPLACE(@AmountCondition,',',' OR ')
		set @AmountCondition = REPLACE(@AmountCondition,'))',')')
	END

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1

END


IF (@AmountCondition is not null and @AmountCondition <> '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_EqualToZero''','Amount = 0')
	END
	SET @index = charindex('E_LessThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_LessThanZero''','Amount < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_GreaterThanZero''','Amount > 0')	
	END
END

-- Hình thức thanh toán
IF (@PayPaidType is not null AND @PayPaidType <> '')
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
-- Export

DECLARE @getdata NVARCHAR(max)
declare @query nvarchar(max)
declare @queryPageSize nvarchar(max)


SET @getdata ='
	CREATE TABLE #tblPermission (id uniqueidentifier primary key )
	INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''',''Sal_UnusualPay''

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


'
set @query = N'						
	-----------------------Lay du lieu tu bang Luong---------------------------
	select 
				hp.ID as ProfileID , hp.CodeEmp, hp.ProfileName, hp.NameEnglish
				,ISNULL(neorg.DivisionName,'' '') AS DivisionName ,ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
				,csct.SalaryClassName, cptl.PositionName, cjttl.JobTitleName,ISNULL(cetl.EN,'' '') AS EmploymentType,cetl2.EN AS LaborType,cnet.NameEntityName AS EmployeeGroupName, cwptl.WorkPlaceName, hp.DateHire, hp.DateQuit,hp.DateEndProbation,cetl3.EN AS EmpStatus,spt.MonthYear		
				,cost.Code AS CostCentreCode, cne.Code AS Group_CostCentreCode, cat.Code AS CostTypeCode,CASE WHEN spt.IsCash = 1 THEN N''Tiền Mặt'' ELSE N''Chuyển khoản'' END AS PayPaidType
				,sup.Amount,cast(dbo.VnrDecrypt(spti.E_Value) as float) as NetIncome
	INTO		#Sal_UnusualPay_Salary
	FROM		Sal_UnusualPay sup
	LEFT JOIN	Sal_PayrollTable spt
		ON		sup.ProfileID = spt.ProfileID AND sup.MonthYear = spt.MonthYear 
	INNER JOIN	Hre_Profile hp 
		ON		hp.id= spt.ProfileID and hp.IsDelete is null
	LEFT JOIN	Cat_OrgStructure cos 
		ON		cos.ID = spt.OrgStructureID
	LEFT JOIN	#NameEnglishORG neorg 
		ON		neorg.OrgStructureID = spt.OrgStructureID
	LEFT JOIN	Cat_bank cb
		ON		cb.ID = sup.BankID
	LEFT JOIN	Cat_SalaryClass csc
		ON		csc.ID = spt.SalaryClassID
	LEFT JOIN	Cat_SalaryClass_Translate csct
		ON		csct.OriginID = spt.SalaryClassID
	LEFT JOIN	Cat_Position_Translate cptl
		ON		cptl.OriginID = spt.PositionID
	LEFT JOIN	Cat_JobTitle_Translate cjttl
		ON		cjttl.OriginID = spt.JobTitleID
	LEFT JOIN	Cat_WorkPlace_Translate cwptl
		ON		cwptl.OriginID = spt.WorkPlaceID
	LEFT JOIN	Cat_NameEntity_Translate cnet
		ON		cnet.OriginID = spt.EmployeeGroupID
	LEFT JOIN	Sal_PayrollTableItem spti
		ON		Spti.PayrollTableID = spt.ID 
				AND	spti.Code = ''AVN_NetIncome'' AND spti.Isdelete IS NULL
	LEFT JOIN	Cat_CostCentre Cost
		ON		Cost.ID = spt.CostcentreID
	LEFT JOIN	Cat_NameEntity cne
		ON		cne.ID = cost.CostCentreGroupID
	LEFT JOIN	Cat_AbilityTile cat
		ON		cat.ID = csc.AbilityTitleID
	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = spt.EmploymentType 
						AND cetl.EnumName = ''EmploymentType'' AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl
	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = spt.LaborType 
						AND cetl.EnumName = ''LaborType'' AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl2

	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = spt.EmpStatus 
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

	WHERE		sup.IsDelete is null
		AND		spt.Isdelete IS NULL
		AND		sup.Amount > 0
		AND		(hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart )
		AND		hp.DateHire <= @DateEnd
		AND		exists (Select * from #tblPermission tpm where id = hp.id )
				'+ISNULL(@condition,'')+'

	SELECT		*
				,CASE WHEN DateQuit <= @DateEnd THEN ''Resigned'' ELSE CASE WHEN NetIncome = 0 THEN ''Have no salary'' ELSE '''' END END AS ReasonOfDifference
				,ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as RowNumber, GETDATE() AS DateExport
				,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID",NULL AS "condi.EmploymentType",NULL AS "condi.WorkPlaceID", NULL AS "hp.DateHire", NULL AS "hp.DateQuit", NULL AS "hp.DateEndProbation"
				,NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType", NULL AS "AmountCondition", NULL AS "condi.CostCentreID", NULL AS "csc.AbilityTitleID", NULL AS "cost.CostCentreGroupID"
				,NULL AS "condi.EmpStatus"
	INTO		#Results
	FROM		#Sal_UnusualPay_Salary
	WHERE		NetIncome = 0 OR NetIncome IS NULL OR DateQuit <= @DateEnd
				'+ISNULL(@AmountCondition,'')+'
				'+ISNULL(@PayPaidType,'')+' 
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
	drop table #tblPermission
	drop table #Sal_UnusualPay_Salary
	DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG
	'
print (@getdata)
print (@query)
PRINT (@queryPageSize )
exec(@getdata + @query +' '+ @queryPageSize )


END
--rpt_advance_difference_salary
---Nam Ta: 07/8/2021: BC tam ung luong thang
ALTER proc rpt_advance_report
@condition nvarchar(max) = " and (MonthYear = '2022-03-01') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'khang.nguyen'
as
begin

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
		SET @condition =  ' and (MonthYear = ''2022-03-01'') '
END;

----Condition----
DECLARE @MonthYearCondition VARCHAR(100) = ' '
DECLARE @MonthYearSP nvarchar(50) = ' '
DECLARE @AmountCondition nvarchar(100) = ''
DECLARE @PayPaidType nvarchar(200) = ''

-- cat dieu kien
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
		set @MonthYearCondition = @TempCondition
		SET @MonthYearSP = REPLACE(@TempCondition,'''','''''')
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

	SET @index = CHARINDEX('(condi.EmpStatus ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.EmpStatus ','(sup.EmpStatus ')
	END

	SET @index = CHARINDEX('(condi.CostCentreID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.CostCentreID ','(hwh.CostCentreID ')
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
							
	set @index = charindex('(PayPaidType ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @PayPaidType = @TempCondition
	END

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1

END


--- Giá trị
IF (@AmountCondition is not null and @AmountCondition <> '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_EqualToZero''','AdvanceAmount = 0')
	END
	SET @index = charindex('E_LessThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_LessThanZero''','AdvanceAmount < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_GreaterThanZero''','AdvanceAmount > 0')	
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

IF charindex(N'Chuyển khoản%',@PayPaidType,0) >0
BEGIN
SET @PayPaidType = REPLACE(@PayPaidType,N'Chuyển khoản%'')',N'Chuyển khoản%'' OR PayPaidType like ''HRM_DynLang_Salary_Transfer'')')
END

-- Export


DECLARE @GetData nvarchar(max)
DECLARE @query nvarchar(max)
DECLARE @UnionData NVARCHAR(max)
DECLARE @queryPageSize nvarchar(max)



set @GetData = '
	CREATE TABLE #tblPermission (id uniqueidentifier primary key )
	INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''',''Hre_Profile''

	--------------------------------Lay bang luong chinh-------------------------------------
	select spt.* into #Sal_UnusualPay from Sal_UnusualPay spt join #tblPermission tb on spt.ProfileID = tb.ID
	where isdelete is null '+@MonthYearCondition+'

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
	DECLARE @DateStart DATE, @DateEnd DATE, @StartMonth  DATE
	SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYearCondition+'

	---Ngay ket thuc ky ung
	DECLARE @UnusualDay INT
	DECLARE @DateEndAdvance DATETIME

	SELECT @UnusualDay = value1 from Sys_AllSetting where isdelete is null and Name like ''%AL_Unusualpay_DaykeepUnusualpay%''
	SET @DateEndAdvance = DATEADD(DAY,@UnusualDay -1,@StartMonth)

	--- split costcentre of orgstructure
 	SELECT		cos.ID as OrgstructureID,spl.CostCentreID 
	INTO		#OrgSplitCost
	FROM		dbo.Cat_OrgStructure cos
	OUTER APPLY ( SELECT id AS CostCentreID FROM SPLIT_To_NVARCHAR( cos.GroupCostCentreID) ) spl

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

SET @query=
'	
	-----------------------Lay du lieu tu bang Luong---------------------------
	;WITH Sal_UnusualPay_New AS
	(
	select		' +@Top+ ' 
				hp.ID AS ProfileID , hp.CodeEmp, hp.ProfileName
				--,ISNULL(neorg.DivisionName,'' '') AS DivisionName ,ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
				,cou.E_BRANCH AS DivisionName, cou.E_UNIT AS CenterName, cou.E_DIVISION AS DepartmentName, cou.E_DEPARTMENT AS SectionName, cou.E_TEAM AS UnitName
				,ISNULL(neorg.DivisionOrder,-881507) AS DivisionOrder, ISNULL(neorg.CenterOrder,-771507) AS CenterOrder , ISNULL(neorg.DepartmentOrder,-661507) AS DepartmentOrder ,ISNULL(neorg.SectionOrder,-551507) AS SectionOrder,ISNULL(neorg.UnitOrder,-441507) AS UnitOrder
				,ISNULL(sup.Amount,0) as AdvanceAmount,cost.Code AS CostCentreCode, cne.Code AS Group_CostCentreCode, cat.Code AS CostTypeCode, supi.Amount AS PayPaidType,sup.MonthYear
	FROM		#Sal_UnusualPay sup 
	INNER JOIN	Hre_Profile hp
		ON		hp.id= sup.ProfileID
	LEFT JOIN	#Hre_WorkHistory hwh 
		ON		hp.ID = hwh.ProfileID 
	LEFT JOIN	#OrgSplitCost osc
		ON		osc.CostCentreID = hwh.CostCentreID
	LEFT JOIN	Cat_OrgStructure cos 
		ON		cos.ID = osc.OrgstructureID
	LEFT JOIN	Cat_OrgUnit cou
		ON		cou.OrgstructureID = osc.OrgstructureID
	LEFT JOIN	#NameEnglishORG neorg 
		ON		neorg.OrgStructureID = osc.OrgstructureID
	LEFT JOIN	Cat_CostCentre cost
		ON		cost.ID = hwh.CostcentreID
	LEFT JOIN	Cat_NameEntity cne
		ON		cne.ID = cost.CostCentreGroupID
	LEFT JOIN	Sal_PayrollTable spt
		ON		sup.ProfileID = spt.ProfileID AND sup.MonthYear = spt.MonthYear AND spt.IsDelete IS NULL
	LEFT JOIN	Sal_UnusualPayItem supi
		ON		supi.UnusualPayID = sup.ID 
				AND supi.Code = ''SAL_SALARYINFORMATION_ISCASH_BYUNUSUALPAY'' AND supi.Isdelete IS NULL
	LEFT JOIN	Cat_SalaryClass csc
		ON		csc.ID = hwh.SalaryClassID
	LEFT JOIN	Cat_AbilityTile cat
		ON		cat.ID = csc.AbilityTitleID
	WHERE		hp.IsDelete is null
		AND		hp.DateHire <= @DateEndAdvance
		AND		( hp.DateQuit IS NULL OR hp.DateQuit > @DateEndAdvance)
		AND		exists (Select * from #tblPermission tpm where id = hp.id )
		'+ISNULL(@condition,'')+'
	)
	Select *
	into #Sal_UnusualPay_New
	from Sal_UnusualPay_New 
	where 1 = 1
	'+ISNULL(@AmountCondition,'')+'
	'+ISNULL(@PayPaidType,'')+'

'
SET @UnionData =
'		
	SELECT		*, CONVERT(DECIMAL(12,2),1) AS Rate, 0 AS IsRoot,CONVERT(DECIMAL(12,2),1) AS NoEmployee
	INTO		#List_emp_costcentre_share
	FROM		#Sal_UnusualPay_New
	UNION
				( 
				SELECT		' +@Top+ ' 
							sccs.ProfileID, lec.CodeEmp, lec.ProfileName
							--,ISNULL(neorg.DivisionName,'' '') AS DivisionName ,ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
							,cou.E_BRANCH AS DivisionName, cou.E_UNIT AS CenterName, cou.E_DIVISION AS DepartmentName, cou.E_DEPARTMENT AS SectionName, cou.E_TEAM AS UnitName
							,ISNULL(neorg.DivisionOrder,-881507) AS DivisionOrder, ISNULL(neorg.CenterOrder,-771507) AS CenterOrder , ISNULL(neorg.DepartmentOrder,-661507) AS DepartmentOrder ,ISNULL(neorg.SectionOrder,-551507) AS SectionOrder,ISNULL(neorg.UnitOrder,-441507) AS UnitOrder
							,lec.AdvanceAmount ,cost.Code AS CostCentreCode,cne.Code AS Group_CostCentreCode, lec.CostTypeCode,lec.PayPaidType,lec.MonthYear
							,CONVERT(DECIMAL(12,2),sccs.Rate/100) AS Rate
							,ROW_NUMBER() OVER(PARTITION BY sccs.ProfileID ORDER BY sccs.Rate DESC) AS IsRoot,CONVERT(DECIMAL(12,2),1) AS NoEmployee
				FROM		Sal_CostCentreSal sccs
				LEFT JOIN	Cat_CostCentre cost
					ON		cost.ID = sccs.CostcentreID
				LEFT JOIN	Cat_NameEntity cne
					ON		cne.ID = cost.CostCentreGroupID
				LEFT JOIN	Cat_OrgUnit cou
					ON		cou.OrgstructureID = sccs.OrgstructureID
				LEFT JOIN	#NameEnglishORG neorg
					ON		neorg.OrgStructureID = sccs.OrgStructureID
				INNER JOIN	#Sal_UnusualPay_New lec
					ON		lec.ProfileID = sccs.ProfileID
				WHERE		sccs.DateStart <= @DateEnd AND ( sccs.DateEnd >= @DateStart OR sccs.DateEnd IS NULL )
							AND sccs.IsDelete IS NULL
				)
		
	---Tinh tong Phan bo Rate cua tung nguoi
	SELECT		ProfileID, Sum(Rate) AS SumRateShare
	INTO		#SumRateShare
	FROM		#List_emp_costcentre_share
	WHERE		IsRoot <> 0
	GROUP BY	ProfileID

	----Update lai rate cho dong thong tin goc
	UPDATE		r
	SET			r.Rate =  CASE WHEN 1 - ISNULL(s.SumRateShare,0) > 0 THEN 1 - ISNULL(s.SumRateShare,0) ELSE 0 END
	FROM		#List_emp_costcentre_share r
	INNER JOIN	#SumRateShare s
		ON		r.ProfileID = s.ProfileID
	WHERE		r.IsRoot = 0

	---- Xoa dong goc neu Rate = 0
	DELETE		#List_emp_costcentre_share WHERE IsRoot = 0 AND Rate = 0

	--Update Amount theo Rate
	UPDATE		#List_emp_costcentre_share
	SET			AdvanceAmount = AdvanceAmount * Rate
				,NoEmployee = NoEmployee * Rate

	SELECT		DivisionName,CenterName,DepartmentName, SectionName,UnitName,CostCentreCode,Group_CostCentreCode,CostTypeCode,SUM(AdvanceAmount) AS SumAdvanceAmount, SUM(NoEmployee) AS NoEmployee,MonthYear,DivisionOrder,CenterOrder,DepartmentOrder,SectionOrder,UnitOrder
	INTO		#ResultsGroup
	FROM		#List_emp_costcentre_share
	GROUP BY	DivisionOrder,DivisionName, CenterOrder,CenterName,DepartmentOrder,DepartmentName,SectionOrder, SectionName,UnitOrder,UnitName,CostCentreCode,Group_CostCentreCode,CostTypeCode,MonthYear

	SELECT		*,ROW_NUMBER() OVER ( ORDER BY DivisionName,DivisionOrder, CenterName,CenterOrder,DepartmentName,DepartmentOrder, SectionName,SectionOrder,UnitName,UnitOrder,CostCentreCode,Group_CostCentreCode,CostTypeCode ) as RowNumber, GETDATE() AS DateExport
				,NULL AS "CodeEmp",NULL AS "cos.OrderNumber",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID",NULL AS "condi.EmploymentType",NULL AS "condi.WorkPlaceID", NULL AS "hp.DateHire", NULL AS "hp.DateQuit",NULL AS "hp.DateEndProbation"
				,NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType", NULL AS "AmountCondition", NULL AS "condi.CostCentreID", NULL AS "csc.AbilityTitleID", NULL AS "cost.CostCentreGroupID"
				,NULL AS "ProfileName", NULL AS "condi.EmpStatus"
	INTO		#Results
	FROM		#ResultsGroup

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
	drop table #tblPermission,#Hre_WorkHistory
	DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG
	DROP TABLE #Sal_UnusualPay,#Sal_UnusualPay_New ,#List_emp_costcentre_share, #SumRateShare, #ResultsGroup

	'
print ( @GetData)
PRINT( @query)
PRINT( @UnionData)
PRINT(@queryPageSize )

exec( @GetData +@query + @UnionData + @queryPageSize )

END

--rpt_advance_report

---Nam Ta: 28/7/2021: Eabking tam ung

ALTER proc rpt_Ebanking_advance
@condition NVARCHAR(MAX) = " and (MonthYear = '2022-02-01') ",
@PageIndex INT = 1,
@PageSize INT = 10000,
@Username VARCHAR(100) = 'Khang.Nguyen'
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
		SET @condition =  ' and (MonthYear = ''2022-02-01'') '
END;

----Condition----
declare @AmountCondition nvarchar(100) = ''
declare @AbilityTitleIDCondittion nvarchar(max) =''
declare @EmployeeGroupIDCondittion nvarchar(max)=''

declare @TransferComment varchar(145) = 'null'
DECLARE @PeriodPayment nvarchar(11) = 'null'
DECLARE @DatePayment nvarchar(100) = 'null'
DECLARE @ValueDate DATE
declare @AccountCompanyNo nvarchar(100) ='null'
DECLARE @MonthYear nvarchar(50) = ' '
DECLARE @PayPaidType nvarchar(100) = ''

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
		SET @MonthYear = @TempCondition
	END

	set @index = charindex('(GroupBank ','('+@tempID,0) 
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
	IF (@index > 0)
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

	SET @index = charindex('(TransferComment ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @TransferComment = REPLACE(@TempCondition,'and (TransferComment like ','')
		set @TransferComment = REPLACE(@TransferComment,')','')
		set @TransferComment = REPLACE(@TransferComment,'%','')
	END

	set @index = charindex('(PeriodPayment ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @PeriodPayment = REPLACE(@TempCondition,'and (PeriodPayment like N','')
		set @PeriodPayment = REPLACE(@PeriodPayment,')','')
		set @PeriodPayment = REPLACE(@PeriodPayment,'%','')
	END
						
	set @index = charindex('(DatePayment ','('+@tempID,0) 
	if(@index > 0)
	begin
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @DatePayment = REPLACE(@TempCondition,'and (DatePayment = ','')
		set @DatePayment = REPLACE(@DatePayment,')','')
		set @DatePayment = REPLACE(@DatePayment,'''','')
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
			           
	set @index = charindex('(AccountCompanyNo ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @AccountCompanyNo = REPLACE(@TempCondition,'and (AccountCompanyNo like N','')
		set @AccountCompanyNo = REPLACE(@AccountCompanyNo,')','')
		set @AccountCompanyNo = REPLACE(@AccountCompanyNo,'%','')
				
	end

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
drop table #tableTempCondition    

IF @DatePayment <> 'null'
BEGIN
SET @ValueDate = CONVERT(DATETIME,@DatePayment)
SET @DatePayment = RIGHT(CONVERT(VARCHAR(20), @ValueDate, 112),6)
SET @DatePayment = '''' + @DatePayment + ''''
END

--- Giá trị
IF (@AmountCondition is not null and @AmountCondition <> '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_EqualToZero''','PaymentAmount = 0')
	END
	SET @index = charindex('E_LessThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_LessThanZero''','PaymentAmount < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_GreaterThanZero''','PaymentAmount > 0')	
	END
END


---- Hình thức thanh toán
--IF (@PayPaidType is not null AND @PayPaidType <> '')
--BEGIN
--	SET @index = charindex('Cash',@PayPaidType,0) 
--	IF(@index > 0)
--	BEGIN
--	SET @PayPaidType = REPLACE(@PayPaidType,'Cash',N'Tiền mặt')
--	END
--	SET @index = charindex('Transfer',@PayPaidType,0) 
--	IF(@index > 0)
--	BEGIN
--	SET @PayPaidType = REPLACE(@PayPaidType,'Transfer',N'Chuyển khoản')
--	END
--END

SET @PayPaidType = N' AND ( PayPaidType = N''Chuyển khoản'' OR PayPaidType = ''HRM_DynLang_Salary_Transfer'') '  

DECLARE @getdata varchar(max)
declare @query varchar(max)
declare @query2 nvarchar(max)
declare @queryPageSize nvarchar(max)

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

set @query = N'

	-----------------------Lay du lieu tu bang Luong---------------------------
	;WITH Sal_UnusualPay_New AS
	(
	select		
				hp.ID AS ProfileID , hp.CodeEmp, hp.ProfileName
				,ISNULL(neorg.DivisionName,'' '') AS DivisionName ,ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
				,csct.SalaryClassName,cptl.PositionName, cjttl.JobTitleName,ISNULL(cetl.EN,'' '') AS EmploymentType,cetl2.EN AS LaborType,cnet.NameEntityName AS EmployeeGroupName, cwptl.WorkPlaceName, hp.DateHire, hp.DateQuit,hp.DateEndProbation,ISNULL(cetl3.EN ,cetl3.VN) AS EmpStatus,sup.MonthYear
				,ISNULL(sup.Amount,0) AS PaymentAmount,supi.Amount AS PayPaidType
				,sup.AccountNo,ISNULL(ssim.AccountName,hp.NameEnglish) AS AccountName,cb.GroupBank, cb.BankName,supi2.Amount AS BranchName
				,cb.ID As BankID
	FROM		#Sal_UnusualPay sup
	LEFT JOIN	#Hre_WorkHistory hwh 
		ON		sup.ProfileID = hwh.ProfileID
	INNER JOIN	Hre_Profile hp 
		ON		hp.id= sup.ProfileID
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
	LEFT JOIN	Sal_UnusualPayItem supi
		ON		supi.UnusualPayID = sup.ID 
				AND supi.Code = ''SAL_SALARYINFORMATION_ISCASH_BYUNUSUALPAY'' AND supi.Isdelete IS NULL
	LEFT JOIN	Sal_UnusualPayItem supi2
		ON		supi2.UnusualPayID = sup.ID AND supi2.Code = ''SAL_SALARYINFORMATION_BRANCHNAME1''
	LEFT JOIN	Sal_SalaryInformation ssim
		ON		ssim.ProfileID = sup.ProfileID AND ssim.BankID = sup.BankID AND ssim.AccountNo = sup.AccountNo AND ssim.IsDelete IS NULL
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
'
SET @query2=
N'	
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
						AND sg.MonthStart <= @DateEnd AND ( sg.MonthEnd IS NULL OR sg.MonthEnd >= @DateStart )
						AND sg.Isdelete IS NULL
				ORDER BY sg.DateUpdate DESC
				) cetl4

	WHERE		sup.IsDelete is null
		AND		hp.IsDelete is null
		AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart )
		AND		hp.DateHire <= @DateEndAdvance
		AND		exists (Select * from #tblPermission tpm where id = hp.id )
				'+ISNULL(@condition,'')+'
	)
	Select *
	into #Sal_UnusualPay_New 
	from Sal_UnusualPay_New 
	WHERE  1 = 1
	'+ISNULL(@AmountCondition,'')+'
	'+ISNULL(@PayPaidType,'')+' 

	DECLARE @CountProfile INT
	DECLARE @SumAmount DECIMAL

	SELECT @CountProfile = COUNT(ProfileID) , @SumAmount= SUM(PaymentAmount)
	FROM #Sal_UnusualPay_New 

	-----------------------Tao 2 dong header va do du lieu vao cac cot---------------------------
					
SELECT
		supn.*
		,cbr.BranchSortCode,cbr.BranchSwiftCode
		, '+@PeriodPayment+' AS "PeriodPayment",'+@DatePayment+' AS "DatePayment", '+@AccountCompanyNo+' AS "AccountCompanyNo", '+@TransferComment+' AS "TransferComment"
		,''0001'' AS A1, RIGHT(CONVERT(VARCHAR(10),GETDATE(),112),6) AS B1,''0001'' AS C1
		,''0010'' AS A2, ''00001'' AS B2, '+@PeriodPayment+' AS C2, '+@DatePayment+' AS D2, ''0'' AS E2, ''1'' AS F2, '+@AccountCompanyNo+' AS G2, ''VND'' AS H2
		,Convert(varchar(10),@CountProfile) AS I2,Convert(varchar(20),@SumAmount) AS J2
		,''0100'' AS A
		,''00001'' AS B
		,RIGHT(1000000 + ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp),5 ) AS C
		,''99'' AS D
		,PaymentAmount AS E
		,supn.CodeEmp AS F
		,supn.AccountNo AS G
		,supn.AccountName AS H
		,NULL AS I,NULL AS J
		,cbr.BranchSwiftCode AS K
		,NULL AS L, NULL AS M, NULL AS N, NULL AS O,NULL AS P,NULL AS Q ,NULL AS R, NULL AS S, NULL AS T
		,'+@TransferComment+' AS U
		,NULL AS V,NULL AS W,NULL AS X,NULL AS Y,NULL AS Z
		,NULL AS AA,NULL AS AB,NULL AS AC,NULL AS AD, NULL AS AE,NULL AS AF,NULL AS AG,NULL AS AH,NULL AS AI, NULL AS AJ
		,NULL AS AK,NULL AS AL,NULL AS AM,NULL AS AN, NULL AS AO,NULL AS AP,NULL AS AQ,NULL AS AR
		,ROW_NUMBER() OVER (ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as RowNumber
		,NULL AS "cos.OrderNumber",NULL AS "condi.EmploymentType",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "condi.WorkPlaceID"
		,NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType", NULL AS "AmountCondition"
		,NULL AS "condi.EmpStatus"

INTO		#Results
FROM		#Sal_UnusualPay_New supn
OUTER APPLY	
		(SELECT TOP(1) BranchSwiftCode,BranchSortCode
		FROM	Cat_Branch cbr
		WHERE	cbr.BranchName = supn.BranchName AND cbr.BankID = supn.BankID
				AND cbr.IsDelete IS NULL
		ORDER	BY cbr.DateUpdate DESC
		) cbr

	'
set @queryPageSize = ' 

	ALTER TABLE #Results ADD TotalRow int
	declare @totalRow int
	SELECT @totalRow = COUNT(*) FROM #Results
	update #Results set TotalRow = @totalRow
	SELECT	RowNumber AS STT,*
	FROM	#Results 
	WHERE	RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
	ORDER BY RowNumber
						
	DROP TABLE #Results
	drop table #tblPermission
	drop table #Sal_UnusualPay_New, #Hre_WorkHistory
	'
PRINT(@getdata)
PRINT(@query)
PRINT(@query2)
PRINT(@queryPageSize)

EXEC (@getdata + @query +@query2 + @queryPageSize )

END


--rpt_Ebanking_advance
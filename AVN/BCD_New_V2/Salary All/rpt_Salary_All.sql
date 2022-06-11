----Nam Ta: 18/8/2021: Bang Luong All: Bang luong, DS khong nhan luong, Bang Luong Ngan Hang
ALTER proc rpt_Salary_All
@condition nvarchar(max) = " and (MonthYear = '2022-02-01') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'Khang.Nguyen'
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
end;

----Condition----
DECLARE @MonthYearCondition VARCHAR(100) = ' '
DECLARE @MonthYearSP VARCHAR(50) = ' '
DECLARE @PayPaidType NVARCHAR(200) = ''
DECLARE @AmountCondition VARCHAR(500) = ''
DECLARE @IsSalary VARCHAR(500) =' '
DECLARE @IsNotSalary VARCHAR(500) =' '
DECLARE @IsSalaryBanking VARCHAR(500) =' '
DECLARE @CheckData VARCHAR(1000) =''

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
	set @index = charindex('MonthYear = ',@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @MonthYearCondition = @tempCondition
		SET @MonthYearSP = REPLACE(@tempCondition,'''','''''')
	END
            
	SET @index = charindex('(GroupBank ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @condition = REPLACE(@condition,'(Groupbank ','(cb.Groupbank ')
	END
            
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
     	SET @condition = REPLACE(@condition,'(condi.EmpStatus ','(spt.EmpStatus ')
	END

	set @index = charindex('(PayPaidType ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCondition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @PayPaidType = @tempCondition
	END

	SET @index = charindex('(AmountCondition ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @AmountCondition = REPLACE(@tempCondition,'(AmountCondition in ','')
		set @AmountCondition = REPLACE(@AmountCondition,',',' OR ')
		set @AmountCondition = REPLACE(@AmountCondition,'))',')')
	END     

	set @index = charindex('(IsSalary ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCondition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @IsSalary = @tempCondition
		set @IsSalary = REPLACE(@IsSalary,' ','') 
	END

	set @index = charindex('(IsNotSalary ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCondition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @IsNotSalary = @tempCondition
		set @IsNotSalary = REPLACE(@tempCondition,' ','') 
	END

	set @index = charindex('(IsSalaryBanking ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @tempCondition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @IsSalaryBanking = @tempCondition
		set @IsSalaryBanking = REPLACE(@IsSalaryBanking,' ','') 
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
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_EqualToZero''','SalaryAmount = 0')
	END
	SET @index = charindex('E_LessThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_LessThanZero''','SalaryAmount < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondition,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_GreaterThanZero''','SalaryAmount > 0')	
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

-- Dieu kien loai bao cao: co luong, khong co luong, co ngan hang 
IF CHARINDEX('IsSalary=1',@IsSalary,0) > 0
BEGIN
	SET @CheckData += ' AND PayrollTableID IS NOT NULL '
END
IF CHARINDEX('IsNotSalary=1',@IsNotSalary,0) > 0
BEGIN
	IF LEN(@CheckData) > 2
	BEGIN
		SET @CheckData += ' OR ( SalaryAmount = 0 OR PayrollTableID IS NULL ) '
	END
	ELSE
		SET @CheckData += ' AND ( SalaryAmount = 0 OR PayrollTableID IS NULL ) '
END
IF CHARINDEX('IsSalaryBanking=1',@IsSalaryBanking,0) > 0
BEGIN
	IF LEN(@CheckData) > 2
	BEGIN
		SET @CheckData += ' OR ( PayrollTableID IS NOT NULL  AND AccountNo IS NOT NULL ) '
	END
	ELSE
		SET @CheckData += ' AND ( PayrollTableID IS NOT NULL AND AccountNo IS NOT NULL ) '
END

--IF @CheckData = ''
--BEGIN
--SET @CheckData =' AND PayrollTableID IS NOT NULL '
--END

-- Export
DECLARE @insertTable VARCHAR(max)
DECLARE @getdata NVARCHAR(max)
DECLARE @query NVARCHAR(MAX)
DECLARE @query2 NVARCHAR(MAX)
DECLARE @pivot VARCHAR(max)
DECLARE @queryPageSize VARCHAR(max)
	
DECLARE @Element VARCHAR(max)
DECLARE @ElementPivot VARCHAR(max)

SET @Element = ' AND spti.Code IN( ''NotHaveSalary'', ''AVN_LCB'',''AVN_NCTL'',''AVN_TONGLUONGNGAYCONG'',''AVN_PCTheoLuong_SUM'',''AVN_OT_SUM'',''AVN_NS_SUM'',''AVN_ThuNhapKhac_TrongThang'',''AVN_TongThuong_TrongThang''
,''AVN_TruyLinh'',''AVN_BHXH_C'',''AVN_BHYT_C'',''AVN_BHTN_C'',''AVN_BHXH_BHYT_BHTN_C'',''AVN_Deduction_SUM'',''AVN_TruyThu'',''AVN_BHXH_E'',''AVN_BHYT_E'',''AVN_BHTN_E'',''AVN_TT_BHYT_E'',''AVN_ThuePIT''
,''AVN_LuongThuong_SUM'',''AVN_ThuNhapChiuThue'',''AVN_GiamTruTax'',''AVN_TinhThue'',''AVN_GrossIncome'',''AVN_AdvancePay'',''AVN_NetIncome'' )'

SET @ElementPivot = '[NotHaveSalary], [AVN_LCB],[AVN_NCTL],[AVN_TONGLUONGNGAYCONG],[AVN_PCTheoLuong_SUM],[AVN_OT_SUM],[AVN_NS_SUM],[AVN_ThuNhapKhac_TrongThang],[AVN_TongThuong_TrongThang],[AVN_TruyLinh],[AVN_BHXH_C]
,[AVN_BHYT_C],[AVN_BHTN_C],[AVN_BHXH_BHYT_BHTN_C],[AVN_Deduction_SUM],[AVN_TruyThu],[AVN_BHXH_E],[AVN_BHYT_E],[AVN_BHTN_E],[AVN_TT_BHYT_E],[AVN_ThuePIT],[AVN_LuongThuong_SUM],[AVN_ThuNhapChiuThue],[AVN_GiamTruTax]
,[AVN_TinhThue],[AVN_GrossIncome],[AVN_AdvancePay],[AVN_NetIncome]'



SET @insertTable = '
CREATE TABLE #CountLeaveDay ( ProfileID uniqueidentifier primary key, ReasonLeave NVARCHAR(100))
INSERT INTO #CountLeaveDay EXEC Countleaveday_EachEmployee '''+@MonthYearSP+''',0

'

set @getdata = '
			
	CREATE TABLE #tblPermission (id uniqueidentifier primary key )
	INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'

	--------------------------------Lay bang luong chinh-------------------------------------
	select s.* into #Sal_PayrollTable from Sal_PayrollTable s join #tblPermission tb on s.ProfileID = tb.ID
	where isdelete is null '+@MonthYearCondition+'
	print(''#Sal_PayrollTable'')

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
		
	DECLARE @OrtherGroupBank Nvarchar(200)
	SET @OrtherGroupBank = ( SELECT DISTINCT BankName FROM dbo.Cat_Bank WHERE GroupBank = ''VCB'' AND IsDelete IS NULL )


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
SET @query= '
	-----------------------Lay du lieu tu bang Luong---------------------------
	;WITH Sal_PayrollTable_New AS
	(
	select		' +@Top+ N'
				hp.ID AS ProfileID , hp.CodeEmp, hp.ProfileName
				,ISNULL(neorg.DivisionName,'' '') AS DivisionName ,ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
				,csct.SalaryClassName, cptl.PositionName, cjttl.JobTitleName,ISNULL(cetl.EN,'' '') AS EmploymentType,cetl2.EN AS LaborType,cnet.NameEntityName AS EmployeeGroupName, cwptl.WorkPlaceName
				,hp.DateHire, hp.DateQuit,ISNULL(cetl3.VN ,cetl3.EN) AS EmpStatus,spt.MonthYear
				,ISNULL(cast(dbo.VnrDecrypt(spti.E_Value) as float),0) as SalaryAmount
				,CASE WHEN dbo.VnrDecrypt(spti.E_Value) > 0 THEN NULL
					ELSE
					CASE WHEN cld.ReasonLeave <>'''' THEN '' + The unpaid leave days: '' +''"''+ cld.ReasonLeave + ''"'' + '' '' ELSE '''' END +
					CASE WHEN spt.ID IS NULL THEN N'' + Absence in salary sheet '' ELSE '''' END 
				END AS ReasonOfSALARY
				,CASE WHEN spt.IsCash = 1 THEN N''Tiền Mặt'' ELSE N''Chuyển khoản'' END AS PayPaidType
				,cb.GroupBank,spt.AccountNo,ssim.AccountName AS AccountName, cb.BankName, dbo.VnrDecrypt(spti2.E_Value) AS BranchName
				,CASE WHEN cb.GroupBank IN(''ICB'', ''BIDV'', ''VCB'',''NN'') THEN ISNULL(cb.BankName,''NULL'') ELSE @OrtherGroupBank END AS GroupBankName,cb.BankName + '', '' + dbo.VnrDecrypt(spti2.E_Value) AS BankBranchName
				,ISNULL(neorg.DivisionOrder,-881507) AS DivisionOrder, ISNULL(neorg.CenterOrder,-771507) AS CenterOrder , ISNULL(neorg.DepartmentOrder,-661507) AS DepartmentOrder ,ISNULL(neorg.SectionOrder,-551507) AS SectionOrder
				,ISNULL(neorg.UnitOrder,-441507) AS UnitOrder
				,ISNULL(cetl.EN,'' '') AS EmploymentTypeGroup
				,spt.ID as PayrollTableID
	FROM		Hre_Profile hp
	LEFT JOIN	#Sal_PayrollTable spt
		ON		hp.id= spt.ProfileID
	LEFT JOIN	#Hre_WorkHistory hwh 
		ON		hp.ID = hwh.ProfileID 
	LEFT JOIN	Cat_OrgStructure cos 
		ON		cos.ID = hwh.OrganizationStructureID
	LEFT JOIN	#NameEnglishORG neorg 
		ON		neorg.OrgStructureID = hwh.OrganizationStructureID
	LEFT JOIN	Cat_bank cb
		ON		cb.ID = spt.BankID
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
	LEFT JOIN	Sal_PayrollTableItem spti
		ON		Spti.PayrollTableID = spt.ID 
				AND spti.Code = ''AVN_NetIncome'' AND spti.Isdelete IS NULL
	LEFT JOIN	Sal_PayrollTableItem spti2
		ON		Spti2.PayrollTableID = spt.ID 
				AND	spti2.Code = ''AVN_Bank_Branch'' AND spti2.Isdelete IS NULL
	LEFT JOIN	Sal_SalaryInformation ssim
		ON		ssim.ProfileID = spt.ProfileID AND ssim.BankID = spt.BankID AND ssim.AccountNo = spt.AccountNo AND ssim.IsDelete IS NULL
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
				WHERE	cetl.EnumKey = spt.EmpStatus 
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

	WHERE		hp.IsDelete is null
		AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart)
		AND		hp.DateHire <= @DateEnd
		AND		exists (Select * from #tblPermission tpm where id = hp.id )
				'+ISNULL(@condition,'')+'
	)
	Select *
	into #Sal_Payrolltable_New
	from Sal_PayrollTable_New 
	where 1 = 1
	'+ISNULL(@PayPaidType,'')+'
	'+ISNULL(@CheckData,'')+ ' 
	'+ISNULL(@AmountCondition,'')+'
	print(''#Sal_Payrolltable_New'');
'
SET @pivot= '
		
	SELECT		* 
	INTO		#Sal_Payrolltable_Pivot
	FROM	
				(
				SELECT * 
				FROM (
						SELECT		sptn.*,ISNULL(spti.Code,''NotHaveSalary'') AS Code, CASE WHEN spti.Code IS NOT NULL THEN cast(dbo.VnrDecrypt(E_Value) as float) ELSE 1  END as AmountSPTI
						FROM		#Sal_Payrolltable_New sptn
						LEFT JOIN	Sal_PayrollTableItem spti
							ON		sptn.PayrollTableID = spti.PayrollTableID
									AND	spti.Isdelete  IS NULL
					) spti
					WHERE	1 = 1 '+@Element+'
				) T

	PIVOT		(
				sum(AmountSPTI) for code  in ( '+@ElementPivot+' )
				) p
					

	SELECT		*
				'+CASE WHEN @IsSalaryBanking = 'AND(IsSalaryBanking=1)' 
				THEN ',ROW_NUMBER() OVER (ORDER BY GroupBankName,BankName,BranchName, DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp) as RowNumber' 
				ELSE ',ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as RowNumber' END+'
				,GETDATE() AS DateExport
				,NULL AS "cos.OrderNumber",NULL AS "condi.EmploymentType",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation"
				,NULL AS "hp.DateQuit",NULL AS "condi.WorkPlaceID",NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType", NULL AS "AmountCondition"
				,NULL AS "condi.EmpStatus",NULL AS "IsSalary", NULL AS "IsNotSalary", NULL AS "IsSalaryBanking"
	INTO		#Results
	FROM		#Sal_Payrolltable_Pivot
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
	DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG
	DROP TABLE #Sal_PayrollTable,#Sal_PayrollTable_new, #Sal_Payrolltable_Pivot,#CountLeaveDay
	
	'
print (@InsertTable)
print (@getdata)
print (@query)
print (@query2)
print (@pivot)
print (@queryPageSize)

exec(@InsertTable + @getdata +@query + @query2 + @pivot+ @queryPageSize )


END
--rpt_Salary_All
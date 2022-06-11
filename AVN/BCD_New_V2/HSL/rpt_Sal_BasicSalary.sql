---Nam Ta: 22/03/2021: HSL, Chenh lech HSL
ALTER proc rpt_Sal_BasicSalary
@condition nvarchar(max) = " and (MonthYear1 = '2022-02-01') and (MonthYear2 = '2022-01-01') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'khang.nguyen'
as
BEGIN

DECLARE @language VARCHAR(20)
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

SELECT @language = value1 FROM dbo.Sys_AllSetting WHERE Name = 'HRM_SYS_USERSETTING_LANGUAGE' AND Value2 = @Username

if ltrim(rtrim(@Condition)) = '' OR @Condition is null
	begin
			set @Top = ' top 0 ';
			SET @condition =  ' and (MonthYear1 = ''2022-02-01'') '
	end;

-- Condition

DECLARE @MonthYearCondition1 VARCHAR(100) = ''
--DECLARE @MonthYear2 nvarchar(50) = ''
DECLARE @MonthYearCondition2 VARCHAR(100) = ''
DECLARE @AmountCompare varchar(500) = ''
DECLARE @EmpStatus NVARCHAR(500) = ''

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

	set @index = charindex('MonthYear1 = ',@tempID,0) 
	if(@index > 0)
	begin
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @MonthYearCondition1 = REPLACE(@tempCondition, 'MonthYear1', 'MonthYear' )
	end

	set @index = charindex('MonthYear2 = ',@tempID,0) 
	if(@index > 0)
	begin
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @MonthYearCondition2 = REPLACE(@tempCondition, 'MonthYear2', 'MonthYear' )
		--set @MonthYear2 = substring(@MonthYearCondition2, patindex('%[0-9]%', @MonthYearCondition2), 10)
	end

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
     	SET @condition = REPLACE(@condition,'(condi.EmploymentType ','(sbs.EmploymentType ')
	END
    
	SET @index = CHARINDEX('(condi.SalaryClassID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.SalaryClassID ','(sbs.ClassRateID ')
	END

	SET @index = CHARINDEX('(condi.PositionID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.PositionID ','(sbs.PositionID ')
	END
	
	SET @index = CHARINDEX('(condi.JobTitleID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.JobTitleID ','(sbs.JobTitleID ')
	END
	
	SET @index = CHARINDEX('(condi.WorkPlaceID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.WorkPlaceID ','(sbs.WorkPlaceID ')
	END
	
	SET @index = CHARINDEX('(condi.EmployeeGroupID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.EmployeeGroupID ','(sbs.EmployeeGroupID ')
	END
		
	SET @index = CHARINDEX('(condi.LaborType ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.LaborType ','(sbs.LaborType ')
	END	

	SET @index = charindex('(AmountCompare ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @AmountCompare = REPLACE(@TempCondition,'(AmountCompare in ','')
		set @AmountCompare = REPLACE(@AmountCompare,',',' OR ')
		set @AmountCompare = REPLACE(@AmountCompare,'))',')')
	END

	set @index = charindex('(condi.EmpStatus ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @EmpStatus = REPLACE(@TempCondition,'(condi.EmpStatus IN ','')
		set @EmpStatus = REPLACE(@EmpStatus,',',' OR ')
		set @EmpStatus = REPLACE(@EmpStatus,'))',')')
	END


	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1

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

--- Giá trị
IF (@AmountCompare is not null and @AmountCompare <> '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCompare,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCompare = REPLACE(@AmountCompare,'''E_EqualToZero''','Sum_Alowance_Compare = 0')
	END
	SET @index = charindex('E_LessThanZero',@AmountCompare,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCompare = REPLACE(@AmountCompare,'''E_LessThanZero''','Sum_Alowance_Compare < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCompare,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCompare = REPLACE(@AmountCompare,'''E_GreaterThanZero''','Sum_Alowance_Compare > 0')	
	END
END


--- lay ra 14 khoan phu cap
DECLARE @i INT = 1
DECLARE @AlowanceAlias VARCHAR(max)=''
DECLARE @SUM_Alowance VARCHAR(max)
DECLARE @AlowanceAlias1 VARCHAR(max)=''
DECLARE @SUM_Alowance1 VARCHAR(max)
DECLARE @AlowanceAlias2 VARCHAR(max)=''
DECLARE @SUM_Alowance2 VARCHAR(max)
DECLARE @AlowanceAlias_Compare VARCHAR(max)=''
DECLARE @SUM_Alowance_Compare VARCHAR(max)


---- Phu cap cua ky hien tai
WHILE @i <= 14
BEGIN
SELECT @AlowanceAlias = COALESCE(@AlowanceAlias + ',','') + 'CAST(dbo.VnrDecrypt(sbs.E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ')AS float) AS ' + Code
FROM Cat_UsualAllowance
WHERE Priotity = @i
SET @i += 1
END 

SET @i = 1
WHILE @i <= 14
BEGIN
SELECT @SUM_Alowance = COALESCE(@SUM_Alowance + ' + ','') + 'CAST(dbo.VnrDecrypt(sbs.E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ') AS float)'
FROM Cat_UsualAllowance
WHERE Priotity = @i
SET @i += 1
END 

SET @SUM_Alowance = ISNULL(@SUM_Alowance,'NULL') + '  + CAST(dbo.VnrDecrypt(sbs.E_GrossAmount) AS float) AS Sum_Alowance'

---- Phu cap cua ky duoc chon moi nhat
SET @i = 1
WHILE @i <= 14
BEGIN
SELECT @AlowanceAlias1 = COALESCE(@AlowanceAlias1 + ',','') + 'CAST(dbo.VnrDecrypt(sbs1.E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ')AS float) AS ' + Code +'_After'
FROM Cat_UsualAllowance
WHERE Priotity = @i
SET @i += 1
END 

SET @i = 1
WHILE @i <= 14
BEGIN
SELECT @SUM_Alowance1 = COALESCE(@SUM_Alowance1 + ' + ','') + 'CAST(dbo.VnrDecrypt(sbs1.E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ') AS float)'
FROM Cat_UsualAllowance
WHERE Priotity = @i
SET @i += 1
END 

SET @SUM_Alowance1 = ISNULL(@SUM_Alowance1,'NULL') + ' + CAST(dbo.VnrDecrypt(sbs1.E_GrossAmount) AS float) AS Sum_Alowance1'

---- Phu cap cua ky duoc chon so sanh
SET @i = 1
WHILE @i <= 14
BEGIN
SELECT @AlowanceAlias2 = COALESCE(@AlowanceAlias2 + ',','') + 'CAST(dbo.VnrDecrypt(sbs2.E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ')AS float) AS ' + Code + '_Before'
FROM Cat_UsualAllowance
WHERE Priotity = @i
SET @i += 1
END 

SET @i = 1
WHILE @i <= 14
BEGIN
SELECT @SUM_Alowance2 = COALESCE(@SUM_Alowance2 + ' + ','') + 'CAST(dbo.VnrDecrypt(sbs2.E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ') AS float)'
FROM Cat_UsualAllowance
WHERE Priotity = @i
SET @i += 1
END 

SET @SUM_Alowance2 = ISNULL(@SUM_Alowance2,'NULL') + ' + CAST(dbo.VnrDecrypt(sbs2.E_GrossAmount) AS float) AS Sum_Alowance2'

---- Phu cap so sanh giua 2 ky
SET @i = 1
WHILE @i <= 14
BEGIN
SELECT @AlowanceAlias_Compare = COALESCE(@AlowanceAlias_Compare + ',','') + 'CAST(dbo.VnrDecrypt(sbs1.E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ')AS float) - CAST(dbo.VnrDecrypt(sbs2.E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ')AS float) AS ' + Code + '_Compare'
FROM Cat_UsualAllowance
WHERE Priotity = @i
SET @i += 1
END 

SET @i = 1
WHILE @i <= 14
BEGIN
SELECT @SUM_Alowance_Compare = COALESCE(@SUM_Alowance_Compare + ' + ','') + 'CAST(dbo.VnrDecrypt(sbs1.E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ') AS float) - CAST(dbo.VnrDecrypt(sbs2.E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ') AS float)'
FROM Cat_UsualAllowance
WHERE Priotity = @i
SET @i += 1
END 

SET @SUM_Alowance_Compare = ISNULL(@SUM_Alowance_Compare,'NULL') + ' + CAST(dbo.VnrDecrypt(sbs1.E_GrossAmount) AS float) - CAST(dbo.VnrDecrypt(sbs2.E_GrossAmount) AS float) AS Sum_Alowance_Compare'

-- Export

DECLARE @getdata VARCHAR(max)
declare @query VARCHAR(max)
declare @query2 NVARCHAR(max)
declare @queryPageSize VARCHAR(max)


SET @getdata ='
	CREATE TABLE #tblPermission (id uniqueidentifier primary key )
	INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''',''Sal_BasicSalary''

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


--- Lay ngay bat dau va ket thuc ky luong hien tai
	DECLARE @DateStart DATETIME, @DateEnd DATETIME, @StartMonth  DATETIME
	SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL AND GETDATE() BETWEEN DateStart AND DateEnd

--- Lay ngay bat dau va ket thuc ky luong
	DECLARE @DateStart1 DATETIME, @DateEnd1 DATETIME, @StartMonth1  DATETIME
	SELECT @DateStart1 = DateStart , @DateEnd1 = DateEnd,  @StartMonth1 = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYearCondition1+'

--- Lay ngay bat dau va ket thuc ky luong so sanh
	DECLARE @DateStart2 DATETIME, @DateEnd2 DATETIME, @StartMonth2  DATETIME
	SELECT @DateStart2 = DateStart , @DateEnd2 = DateEnd,  @StartMonth2 = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYearCondition2+'

'
---Neu chon ky so sanh -> Bao cao so sanh HSL
IF @MonthYearCondition2 IS NOT NULL AND @MonthYearCondition2 <> ''
BEGIN
SET @getdata += '
-- Lay HSL moi nhat theo ky hien tai
	if object_id(''tempdb..#Sal_BasicSalary_Now'') is not null 
		drop table #Sal_BasicSalary_Now;
	;WITH Sal_BasicSalary_Now AS
	(
	select		' +@Top+ ' 
				*,ROW_NUMBER() OVER(PARTITION BY sbs.ProfileID ORDER BY sbs.DateOfEffect DESC) AS rk
	from		Sal_BasicSalary as sbs
	WHERE		sbs.IsDelete is null
				AND	sbs.DateOfEffect <= @DateEnd
				AND	sbs.Status = ''E_APPROVED''
	) 
	SELECT	*
	INTO	#Sal_BasicSalary
	FROM	Sal_BasicSalary_Now 
	WHERE	rk = 1
	print(''#Sal_BasicSalary_Now'');

-- Lay HSL moi nhat theo ky duoc chon
	if object_id(''tempdb..#Sal_BasicSalary1'') is not null 
		drop table #Sal_BasicSalary1;
	;WITH Sal_BasicSalary1 AS
	(
	select		' +@Top+ ' 
				*,ROW_NUMBER() OVER(PARTITION BY sbs.ProfileID ORDER BY sbs.DateOfEffect DESC) AS rk
	from		Sal_BasicSalary as sbs
	WHERE		sbs.IsDelete is null
				AND	sbs.DateOfEffect <= @DateEnd1
				AND	sbs.Status = ''E_APPROVED''
	) 
	SELECT	*
	INTO	#Sal_BasicSalary1
	FROM	Sal_BasicSalary1 
	WHERE	rk = 1
	print(''#Sal_BasicSalary1'');

-- Lay HSL moi nhat theo ky duoc chon
	if object_id(''tempdb..#Sal_BasicSalary2'') is not null 
		drop table #Sal_BasicSalary2;
	;WITH Sal_BasicSalary2 AS
	(
	select		' +@Top+ ' 
				*,ROW_NUMBER() OVER(PARTITION BY sbs.ProfileID ORDER BY sbs.DateOfEffect DESC) AS rk
	from		Sal_BasicSalary as sbs
	WHERE		sbs.IsDelete is null
				AND	sbs.DateOfEffect <= @DateEnd2
				AND	sbs.Status = ''E_APPROVED''
	) 
	SELECT	*
	INTO	#Sal_BasicSalary2
	FROM	Sal_BasicSalary2 
	WHERE	rk = 1
	print(''#Sal_BasicSalary2'');
'
END
ELSE
BEGIN
---khong cho su dung search gia tri so sanh
SET @AmountCompare = ' '
-----
SET @getdata += '
SET @DateStart = @DateStart1
SET @DateEnd = @DateEnd1
SET	@StartMonth = @StartMonth1

-- Lay HSL moi nhat theo ky
	if object_id(''tempdb..#Sal_BasicSalary_Now'') is not null 
		drop table #Sal_BasicSalary_Now;
	;WITH Sal_BasicSalary_Now AS
	(
	select		' +@Top+ ' 
				*,ROW_NUMBER() OVER(PARTITION BY sbs.ProfileID ORDER BY sbs.DateOfEffect DESC) AS rk
	from		Sal_BasicSalary as sbs
	WHERE		sbs.IsDelete is null
				AND	sbs.DateOfEffect <= @DateEnd
				AND	sbs.Status = ''E_APPROVED''
	) 
	SELECT	*
	INTO	#Sal_BasicSalary
	FROM	Sal_BasicSalary_Now 
	WHERE	rk = 1
	print(''#Sal_BasicSalary_Now'');

'
END 

set @query = N'						
	-----------------------Lay du lieu tu HSL---------------------------
	select		' +@Top+ ' 
				hp.ID as ProfileID , hp.CodeEmp, hp.ProfileName, hp.NameEnglish
				'+CASE WHEN @language = 'VN' 
				THEN '
				,E_BRANCH AS DivisionName,E_UNIT AS CenterName,E_DIVISION AS DepartmentName,E_DEPARTMENT AS SectionName,E_TEAM AS UnitName
				,csc.Code AS SalaryClassCode,csc.SalaryClassName, cp.PositionName, cjt.JobTitleName,ISNULL(cetl.VN,'' '') AS EmploymentType,cetl2.VN AS LaborType,cne.NameEntityName AS EmployeeGroupName, cwp.WorkPlaceName				
				'
				ELSE'
				,ISNULL(neorg.DivisionName,'' '') AS DivisionName ,ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
				,csc.Code AS SalaryClassCode,csct.SalaryClassName, cptl.PositionName, cjttl.JobTitleName,ISNULL(cetl.EN,'' '') AS EmploymentType,cetl2.EN AS LaborType,cnet.NameEntityName AS EmployeeGroupName, cwptl.WorkPlaceName
				'END+'
				,cost.Code AS CostCentreCode, cat.Code AS CostTypeCode, hp.DateHire, hp.DateQuit,hp.DateEndProbation,sbs.DateOfEffect 
				'
IF @MonthYearCondition2 IS NOT NULL AND @MonthYearCondition2 <> ''
BEGIN
SET @query +=  
				CASE WHEN @language = 'VN' 
				THEN'
				,sbs2.DateOfEffect AS DateOfEffect_Before, csc2.Code AS SalaryClassCode_Before, csc2.SalaryClassName AS SalaryClassName_Before, cp2.PositionName AS PositionName_Before, cjt2.JobTitleName AS JobTitleName_Before
				,CAST(dbo.VnrDecrypt(sbs2.E_GrossAmount) AS float) AS LCB_Before ' +@AlowanceAlias2+' , ' +@SUM_Alowance2+ '
				,sbs1.DateOfEffect AS DateOfEffect_After, csc1.Code AS SalaryClassCode_After, csc1.SalaryClassName AS SalaryClassName_After, cp1.PositionName AS PositionName_After, cjt1.JobTitleName AS JobTitleName_After
				,CAST(dbo.VnrDecrypt(sbs1.E_GrossAmount) AS float) AS LCB_After ' +@AlowanceAlias1+' , ' +@SUM_Alowance1+ '
				,CASE WHEN ISNULL(csc1.Code,'''') = ISNULL(csc2.Code,'''') THEN ''TRUE'' ELSE ''FALSE'' END AS SalaryClassCode_Compare
				,CASE WHEN ISNULL(csc1.SalaryClassName,'''') = ISNULL(csc2.SalaryClassName,'''') THEN ''TRUE'' ELSE ''FALSE'' END AS SalaryClassName_Compare
				,CASE WHEN ISNULL(cp1.PositionName,'''') = ISNULL(cp2.PositionName,'''') THEN ''TRUE'' ELSE ''FALSE'' END AS PositionName_Compare
				,CASE WHEN ISNULL(cjt1.JobTitleName,'''') = ISNULL(cjt2.JobTitleName,'''') THEN ''TRUE'' ELSE ''FALSE'' END AS JobTitleName_Compare
				'
				ELSE'
				,sbs2.DateOfEffect AS DateOfEffect_Before, csc2.Code AS SalaryClassCode_Before, csct2.SalaryClassName AS SalaryClassName_Before, cptl2.PositionName AS PositionName_Before, cjttl2.JobTitleName AS JobTitleName_Before
				,CAST(dbo.VnrDecrypt(sbs2.E_GrossAmount) AS float) AS LCB_Before ' +@AlowanceAlias2+' , ' +@SUM_Alowance2+ '
				,sbs1.DateOfEffect AS DateOfEffect_After, csc1.Code AS SalaryClassCode_After, csct1.SalaryClassName AS SalaryClassName_After, cptl1.PositionName AS PositionName_After, cjttl1.JobTitleName AS JobTitleName_After
				,CAST(dbo.VnrDecrypt(sbs1.E_GrossAmount) AS float) AS LCB_After ' +@AlowanceAlias1+' , ' +@SUM_Alowance1+ '
				,CASE WHEN ISNULL(csc1.Code,'''') = ISNULL(csc2.Code,'''') THEN ''TRUE'' ELSE ''FALSE'' END AS SalaryClassCode_Compare
				,CASE WHEN ISNULL(csct1.SalaryClassName,'''') = ISNULL(csct2.SalaryClassName,'''') THEN ''TRUE'' ELSE ''FALSE'' END AS SalaryClassName_Compare
				,CASE WHEN ISNULL(cptl1.PositionName,'''') = ISNULL(cptl2.PositionName,'''') THEN ''TRUE'' ELSE ''FALSE'' END AS PositionName_Compare
				,CASE WHEN ISNULL(cjttl1.JobTitleName,'''') = ISNULL(cjttl2.JobTitleName,'''') THEN ''TRUE'' ELSE ''FALSE'' END AS JobTitleName_Compare
				'END
				+'
				,CAST(dbo.VnrDecrypt(sbs1.E_GrossAmount) AS float) - CAST(dbo.VnrDecrypt(sbs2.E_GrossAmount) AS float) AS LCB_Compare ' +@AlowanceAlias_Compare+' , ' +@SUM_Alowance_Compare+ '
				,sbs1.Note,@StartMonth2 AS MonthYear2,@StartMonth1 AS MonthYear1
				'
END
ELSE
BEGIN
SET @query +=	'
				,CAST(dbo.VnrDecrypt(sbs.E_GrossAmount) AS float) AS LCB ' +@AlowanceAlias+' , ' +@SUM_Alowance+ '
				,sbs.Note, NULL AS MonthYear2,@StartMonth1 AS MonthYear1
'
END

SET @query +=	'
				,GETDATE() as "DateExport"
				,NULL AS "cos.OrderNumber",NULL AS "condi.EmploymentType",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit"
				,NULL AS "condi.WorkPlaceID",NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType", NULL AS "condi.EmpStatus"
				,NULL AS "AmountCompare"
	INTO		#Result
	FROM		#Sal_BasicSalary sbs
	INNER JOIN	Hre_Profile hp 
		ON		hp.id= sbs.ProfileID
	LEFT JOIN	Cat_OrgStructure cos
		ON		cos.ID = sbs.OrgStructureID
	LEFT JOIN	Cat_OrgUnit cu 
		ON		sbs.OrgStructureID = cu.OrgStructureID
	LEFT JOIN	#NameEnglishORG neorg 
		ON		neorg.OrgStructureID = sbs.OrgStructureID
	LEFT JOIN	Cat_SalaryClass csc
		ON		csc.ID = sbs.ClassRateID
	LEFT JOIN	Cat_SalaryClass_Translate csct
		ON		csct.OriginID = sbs.ClassRateID
	LEFT JOIN	Cat_Position cp
		ON		cp.ID = sbs.PositionID
	LEFT JOIN	Cat_Position_Translate cptl
		ON		cptl.OriginID = sbs.PositionID
	LEFT JOIN	Cat_JobTitle cjt
		ON		cjt.ID = sbs.JobTitleID
	LEFT JOIN	Cat_JobTitle_Translate cjttl
		ON		cjttl.OriginID = sbs.JobTitleID
	LEFT JOIN	Cat_WorkPlace cwp
		ON		cwp.ID = sbs.WorkPlaceID
	LEFT JOIN	Cat_WorkPlace_Translate cwptl
		ON		cwptl.OriginID = sbs.WorkPlaceID
	LEFT JOIN	Cat_NameEntity cne
		ON		cne.ID = sbs.EmployeeGroupID
	LEFT JOIN	Cat_NameEntity_Translate cnet
		ON		cnet.OriginID = sbs.EmployeeGroupID
	LEFT JOIN	Cat_CostCentre Cost
		ON		Cost.ID = sbs.CostcentreID
	LEFT JOIN	Cat_AbilityTile cat
		ON		cat.ID = csc.AbilityTitleID
	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = sbs.EmploymentType 
						AND cetl.EnumName = ''EmploymentType'' AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl
	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = sbs.LaborType 
						AND cetl.EnumName = ''LaborType'' AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl2
'
IF @MonthYearCondition2 IS NOT NULL AND @MonthYearCondition2 <> ''
BEGIN
SET @query += '
	LEFT JOIN	#Sal_BasicSalary1 sbs1
		ON		sbs.ProfileID = sbs1.ProfileID
	LEFT JOIN	Cat_SalaryClass csc1
		ON		csc1.ID = sbs1.ClassRateID
	LEFT JOIN	Cat_SalaryClass_Translate csct1
		ON		csct1.OriginID = sbs1.ClassRateID
	LEFT JOIN	Cat_Position cp1
		ON		cp1.ID = sbs1.PositionID
	LEFT JOIN	Cat_Position_Translate cptl1
		ON		cptl1.OriginID = sbs1.PositionID
	LEFT JOIN	Cat_JobTitle cjt1
		ON		cjt1.ID = sbs1.JobTitleID
	LEFT JOIN	Cat_JobTitle_Translate cjttl1
		ON		cjttl1.OriginID = sbs1.JobTitleID
	LEFT JOIN	#Sal_BasicSalary2 sbs2
		ON		sbs.ProfileID = sbs2.ProfileID		
	LEFT JOIN	Cat_SalaryClass csc2
		ON		csc2.ID = sbs2.ClassRateID
	LEFT JOIN	Cat_SalaryClass_Translate csct2
		ON		csct2.OriginID = sbs2.ClassRateID
	LEFT JOIN	Cat_Position cp2
		ON		cp2.ID = sbs2.PositionID
	LEFT JOIN	Cat_Position_Translate cptl2
		ON		cptl2.OriginID = sbs2.PositionID
	LEFT JOIN	Cat_JobTitle cjt2
		ON		cjt2.ID = sbs2.JobTitleID
	LEFT JOIN	Cat_JobTitle_Translate cjttl2
		ON		cjttl2.OriginID = sbs2.JobTitleID
'
END

SET @query2 ='
	WHERE		hp.Isdelete IS NULL
		AND		(hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart )
		AND		hp.DateHire <= @DateEnd
		AND		exists (Select * from #tblPermission tpm where id = hp.id )
				'+ISNULL(@condition,'')+'
				'+ISNULL(@EmpStatus,'')+'


	SELECT		*,ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as RowNumber
	INTO		#Results 
	FROM		#Result
	WHERE		1 = 1
				'+ISNULL(@AmountCompare,'')+'

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

	DROP TABLE #Result, #Results, #tblPermission
	DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG
	'

exec(@getdata + @query +' '+ @query2 + @queryPageSize )

--print (@getdata)
--set @Query = replace(replace(@Query, char(13) + char(10), char(10)), char(13), char(10));
--while len(@Query) > 1
--    begin
--        if charindex(char(10), @Query) between 1 and 4000
--            begin
--                    set @CurrentEnd = charindex(char(10), @Query) - 1;
--                    set @Offset = 2;
--            end;
--        else
--            begin
--                    set @CurrentEnd = 4000;
--                    set @Offset = 1;
--            end;   
--        print substring(@Query, 1, @CurrentEnd); 
--        set @Query = substring(@Query, @CurrentEnd + @Offset, len(@Query));   
--    end;
--PRINT(@query2)
--PRINT (@queryPageSize )

END
--rpt_Sal_BasicSalary
---Nam Ta: 02/8/2021: Chenh lech tam ung
ALTER proc rpt_Sal_BasicSalary
@condition nvarchar(max) = " and (MonthYear1 = '2022-02-01') ",
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
DECLARE @MonthYear1 nvarchar(50) = ' '
DECLARE @MonthYearCondition1 VARCHAR(100) = ' '
DECLARE @MonthYear2 nvarchar(50) = ' '
DECLARE @MonthYearCondition2 VARCHAR(100) = ' '
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
		set @MonthYear1 = substring(@MonthYearCondition1, patindex('%[0-9]%', @MonthYearCondition1), 10)
	end

	set @index = charindex('MonthYear2 = ',@tempID,0) 
	if(@index > 0)
	begin
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		set @MonthYearCondition2 = REPLACE(@tempCondition, 'MonthYear2', 'MonthYear' )
		set @MonthYear2 = substring(@MonthYearCondition2, patindex('%[0-9]%', @MonthYearCondition2), 10)
	end


	set @index = charindex('(ProfileName ','('+@tempID,0) 
	if(@index > 0)
	begin
     	SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
	end

	set @index = charindex('(CostCentreGroup ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'AND ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
	END

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1

END

--- lay ra 14 khoan phu cap
DECLARE @i INT = 1
DECLARE @AlowanceAlias VARCHAR(max)=''
DECLARE @SUM_Alowance VARCHAR(max)

WHILE @i <= 14
BEGIN
SELECT @AlowanceAlias = COALESCE(@AlowanceAlias + ',','') + 'CAST(dbo.VnrDecrypt(E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ')AS float) AS ' + Code
FROM Cat_UsualAllowance
WHERE Priotity = @i
SET @i += 1
END 

SET @i = 1
WHILE @i <= 14
BEGIN
SELECT @SUM_Alowance = COALESCE(@SUM_Alowance + ' + ','') + 'CAST(dbo.VnrDecrypt(E_AllowanceAmount' + CONVERT(VARCHAR(2),@i) + ') AS float)'
FROM Cat_UsualAllowance
WHERE Priotity = @i
SET @i += 1
END 

SET @SUM_Alowance = ISNULL(@SUM_Alowance,'NULL') + ' AS Sum_Alowance'

-- Export

DECLARE @getdata VARCHAR(max)
declare @query varchar(max)
declare @queryPageSize varchar(max)


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


	--- Lay ngay bat dau va ket thuc ky luong
	DECLARE @DateStart1 DATETIME, @DateEnd1 DATETIME, @StartMonth1  DATETIME
	SELECT @DateStart1 = DateStart , @DateEnd1 = DateEnd,  @StartMonth1 = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYearCondition1+'


	--- Lay ngay bat dau va ket thuc ky luong so sanh
	DECLARE @DateStart2 DATETIME, @DateEnd2 DATETIME, @StartMonth2  DATETIME
	SELECT @DateStart2 = DateStart , @DateEnd2 = DateEnd,  @StartMonth2 = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYearCondition2+'


	-- Lay HSL moi nhat theo ky
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

'
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
				,cost.CostCentreName, cat.Code AS CostTypeName, hp.DateHire, hp.DateQuit,hp.DateEndProbation,sbs.DateOfEffect,CAST(dbo.VnrDecrypt(sbs.E_GrossAmount) AS float) AS LCB ' +@AlowanceAlias+' , ' +@SUM_Alowance+ '
				, @StartMonth1 AS MonthYear1,GETDATE() as "DateExport"
				,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL as "sbs.PositionID",NULL as "sbs.JobTitleID",NULL as "sbs.ClassRateID"
	INTO		#Result
	FROM		#Sal_BasicSalary1 sbs
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

	WHERE		sbs.IsDelete is null
		AND		hp.Isdelete IS NULL
		AND		(hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart1 )
		AND		hp.DateHire <= @DateEnd1
				'+ISNULL(@condition,'')+'

	SELECT		*,ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as RowNumber
	INTO		#Results 
	FROM		#Result

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
	DROP TABLE #Sal_BasicSalary1
	DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG
	'
print (@getdata)
print (@query)
PRINT (@queryPageSize )
exec(@getdata + @query +' '+ @queryPageSize )


END
--rpt_Sal_BasicSalary
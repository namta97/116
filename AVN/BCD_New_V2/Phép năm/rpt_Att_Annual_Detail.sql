----Nam Ta: 23/05/2022: Bao cao phep nam
ALTER proc rpt_Att_Annual_Detail
@condition nvarchar(max) = " and (MonthYear = '2022-05-01') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'Khang.Nguyen'
AS 
BEGIN 

DECLARE @LanguageID VARCHAR(2)
SELECT @LanguageID = CASE WHEN Value1 = 'VN' THEN 0 ELSE 1 END 
FROM dbo.Sys_AllSetting WHERE Value2 = @Username AND Name = 'HRM_SYS_USERSETTING_LANGUAGE' AND IsDelete IS NULL 
ORDER BY DateUpdate DESC OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
SET @LanguageID = 1

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

----Condition----
DECLARE @MonthYearCondition VARCHAR(100) = ' '
declare @Year varchar(20) = '';
DECLARE @Month VARCHAR(20) = ''
DECLARE @MonthYear VARCHAR(20) = ''
DECLARE @EmpStatus nvarchar(300) = ''
DECLARE @AmountCondition nvarchar(100) = ''
DECLARE @CheckData nvarchar(50) = ''
DECLARE @OrderNumber nvarchar(1000) = ''

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
		set @MonthYear = substring(@MonthYearCondition, patindex('%[0-9]%', @MonthYearCondition), 10)
		SET @Month = MONTH(@MonthYear)
		SET @Year = YEAR(DATEADD(MM,-3,@MonthYear))

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
		SET @TempCondition = 'and ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
		SET @EmpStatus = REPLACE(@TempCondition,'(condi.EmpStatus IN ','')
		SET @EmpStatus = REPLACE(@EmpStatus,',',' OR ')
		SET @EmpStatus = REPLACE(@EmpStatus,'))',')')
	END

	set @index = charindex('CheckData ',@tempID,0)
	if(@index > 0)
	BEGIN
		set @tempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@tempCondition,'')
		set @CheckData = REPLACE(@tempCondition,'CheckData','')
		set @CheckData = REPLACE(@CheckData,'like N','')
		set @CheckData = REPLACE(@CheckData,'%','')
	END

	SET @index = CHARINDEX('(AnnualTransfer ','('+@tempID,0)
	IF(@index > 0)
	BEGIN
		SET @tempCondition = 'and ('+@tempID
		SET @condition = REPLACE(@condition,@tempCondition,'')
		SET @AmountCondition = REPLACE(@tempCondition,'(AnnualTransfer in ','')
		SET @AmountCondition = REPLACE(@AmountCondition,',',' OR ')
		SET @AmountCondition = REPLACE(@AmountCondition,'))',')')
	END

 	SET @index = CHARINDEX('(cos.OrderNumber ','('+@tempID,0)
	IF(@index > 0)
	BEGIN
		SET @tempCondition = 'and ('+@tempID
		SET @OrderNumber = @tempCondition

	END   

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1

END



if(@AmountCondition is not null and @AmountCondition <> '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCondition,0) 
	if(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_EqualToZero''','( AdvancePreviousYear = 0 AND TransferPreviousYear = 0 )')
	END
	set @index = charindex('E_LessThanZero',@AmountCondition,0) 
	if(@index > 0)
	BEGIN
	set @AmountCondition = REPLACE(@AmountCondition,'''E_LessThanZero''','AdvancePreviousYear < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondition,0) 
	if(@index > 0)
	BEGIN
	SET @AmountCondition = REPLACE(@AmountCondition,'''E_GreaterThanZero''','TransferPreviousYear > 0')
	END
end

if(@CheckData is not null and @CheckData <> '')
BEGIN
	SET @index = charindex('E_POSTS',@CheckData,0) 
	if(@index > 0)
	BEGIN
	SET @CheckData = REPLACE(@CheckData,'''E_POSTS''','TotalUsedAnnual > 0')
	END
	set @index = charindex('E_UNEXPECTED',@CheckData,0) 
	if(@index > 0)
	BEGIN
	set @CheckData = REPLACE(@CheckData,'''E_UNEXPECTED''','TotalUsedAnnual = 0')
	END
end

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
	SET @EmpStatus = REPLACE(@EmpStatus,'''E_PROFILE_ACTIVE''','(hp.DateQuit IS NULL OR hp.DateQuit >= @DateEnd)')
END
SET @index = charindex('E_PROFILE_QUIT',@EmpStatus,0) 
IF(@index > 0)
BEGIN
	SET @EmpStatus = REPLACE(@EmpStatus,'''E_PROFILE_QUIT''',' (hp.DateQuit <= @DateEnd AND hp.DateQuit >= @DateStart) ')	
END
END


-- Bang du lieu nam hien tai
DECLARE @FirstMonth DATE;
DECLARE @Count INT = 1;
DECLARE @ListCol VARCHAR(MAX);
DECLARE @ListAlilas VARCHAR(MAX);
DECLARE @ListSumdata VARCHAR(MAX);

SET @FirstMonth = DATEFROMPARTS(@Year, 4, 1);

while @Count <= 12
	begin
		set @ListCol = coalesce(@ListCol + ',', '') + quotename(@FirstMonth);
		set @ListAlilas = coalesce(@ListAlilas + ',', '') + quotename(@FirstMonth) + ' as Data' + convert(varchar(10), @Count);
		SET @ListSumdata	=  COALESCE(@ListSumdata + ' + ', '') + 'ISNULL(' + quotename(@FirstMonth) + ',0)';
		set @FirstMonth = dateadd(month, 1, @FirstMonth);
		set @Count += 1;
	end;

	--SELECT @ListAlilas

--IF @Month < 4 SET @Month +=12
---- Sum data 
--SET @Count = 1
--WHILE @Count <= @Month -3
--    BEGIN
--        SET @ListSumdata	=  COALESCE(@ListSumdata + ' + ', '') + 'ISNULL(Data' + CONVERT(VARCHAR(10), @Count) + ',0)';
--        SET @Count += 1;
--    END;

	--SELECT @ListSumdata

	---rpt_Att_Annual_Detail

-- Export
DECLARE @getdata VARCHAR(max)
DECLARE @query NVARCHAR(MAX)
DECLARE @query2 VARCHAR(MAX)
DECLARE @query3 VARCHAR(MAX)
DECLARE @query4 VARCHAR(MAX)
DECLARE @pivot VARCHAR(max)
DECLARE @queryPageSize VARCHAR(max)
	
set @getdata = '
	DECLARE @LanguageID INT = '+@LanguageID+'
	declare @MonthYear date = ''' + @MonthYear + '''
	declare @Year int = ' + @Year + '

	CREATE TABLE #tblPermission (id uniqueidentifier primary key )
	INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'

	-- Bang du lieu nam hien tai
	declare @FirstMonth date = datefromparts(@Year, 4, 1);
	declare @Count int = 1;
	declare @YearOT table
			(MonthYear date
		   , DateStart date
		   , DateEnd date);
	while @Count <= 12
		  begin
				insert  into @YearOT ( MonthYear, DateStart, DateEnd )
				values  (@FirstMonth, dateadd(day, 20, dateadd(month, -1, @FirstMonth)), dateadd(day, 19, @FirstMonth));
				set @FirstMonth = dateadd(month, 1, @FirstMonth);
				set @Count += 1;
		  end;
	declare @MaxDateEnd date = (select max(DateEnd) from @YearOT);
	declare @MinDateStart date = (select min(DateStart) from @YearOT);

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

	SELECT		a.OrgstructureID,E_BRANCH_CODE, E_DIVISION_CODE, E_DEPARTMENT_CODE
				,CASE WHEN E_BRANCH_CODE IS NOT NULL THEN ISNULL(b.OrgStructureName,E_BRANCH_CODE) END AS E_BRANCH_E
				,CASE WHEN E_DIVISION_CODE IS NOT NULL THEN ISNULL(d.OrgStructureName,E_DIVISION_CODE) END AS E_DIVISION_E
				,CASE WHEN E_DEPARTMENT_CODE IS NOT NULL THEN ISNULL(e.OrgStructureName,E_DEPARTMENT_CODE) END AS E_DEPARTMENT_E
	INTO		#NameEnglishORG_2
	FROM		#UnitCode a
	LEFT JOIN	#NamEnglish b
		ON		a.E_BRANCH_CODE = b.Code
	LEFT JOIN	#NamEnglish d
		ON		a.E_DIVISION_CODE = d.Code
	LEFT JOIN	#NamEnglish e
		ON		a.E_DEPARTMENT_CODE = e.Code

	----Ngay len chinh thuc
	select ProfileID,DateEffective,ROW_NUMBER () OVER (PARTITION BY ProfileID order by ProfileID,DateEffective desc) as flag
	into #LenChinhThuc
	from Hre_WorkHistory
	where isdelete is null and TypeOfTransferID in (SELECT id FROM Cat_NameEntity WHERE isdelete IS NULL AND NameEntityType = ''E_Typeoftransfer'' and Code = ''CTOP'')

	--- Lay ngay bat dau va ket thuc ky luong
	DECLARE @DateStart DATE, @DateEnd DATE, @StartMonth  DATE
	SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYearCondition+'
		
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
	SELECT	hwh.*
	INTO	#Hre_WorkHistory
	FROM	WorkHistory hwh
	WHERE	hwh.rk = 1
		AND		exists (Select * from #tblPermission tpm where id = hwh.ProfileID )
	print(''#Hre_WorkHistory'');

'
SET @query= '
		-----------------------Lay du lieu tu bang phep nam---------------------------
	select		' +@Top+ ' 
				hwh.ProfileID , hp.CodeEmp, hp.ProfileName
				'+ CASE WHEN @LanguageID = 0 
				THEN',cou.E_BRANCH AS DivisionName ,cou.E_UNIT AS CenterName,cou.E_DIVISION AS DepartmentName,cou.E_DEPARTMENT AS SectionName,cou.E_TEAM AS UnitName
				'
				ELSE
				'
				,ISNULL(neorg.DivisionName,E_BRANCH) AS DivisionName ,ISNULL(neorg.CenterName,E_UNIT) AS CenterName, ISNULL(neorg.DepartmentName,E_DIVISION) AS DepartmentName 
				,ISNULL(neorg.SectionName,E_DEPARTMENT) AS SectionName,ISNULL(neorg.UnitName,E_TEAM) AS UnitName
				'
				END
				+'
				,csc.SalaryClassName,cp.PositionName,cj.JobTitleName,CASE WHEN @LanguageID = 0 THEN cetl.VN ELSE ISNULL(cetl.EN,cetl.VN ) END AS EmploymentType
				,CASE WHEN @LanguageID = 0 THEN cetl2.VN ELSE ISNULL(cetl2.EN,cetl2.VN ) END AS LaborType ,cne.NameEntityName AS EmployeeGroupName, cwp.WorkPlaceName
				,hp.DateHire,hp.DateEndProbation,hp.DateQuit, lct.DateEffective AS LenChinhThuc
				,cou.E_BRANCH_CODE
				,concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE) as E_DIVISION_CODE
				,concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE + ''\'', cou.E_DEPARTMENT_CODE) as E_DEPARTMENT_CODE	
				,CASE WHEN aad2.InitAvailable < 0 THEN aad2.InitAvailable ELSE 0 END AS AdvancePreviousYear, CASE WHEN aad2.InitAvailable > 0 THEN aad2.InitAvailable ELSE 0 END AS TransferPreviousYear
				,ISNULL(aad2.Available,0) - ISNULL(aad2.InitAvailable,0) AS YearlyAnnualLeave,ISNULL(aad2.Available,0) AS RealYearlyAnnualLeave
	INTO		#Infor_Hre_WorkHistory
	FROM		#Hre_WorkHistory hwh
	INNER JOIN	Hre_Profile hp
		ON		hp.ID = hwh.ProfileID 
	LEFT JOIN	Cat_OrgStructure cos 
		ON		cos.ID = hwh.OrganizationStructureID
	LEFT JOIN	Cat_OrgUnit cou 
		ON		cou.OrgstructureID = hwh.OrganizationStructureID
	LEFT JOIN	#NameEnglishORG neorg 
		ON		neorg.OrgStructureID = hwh.OrganizationStructureID
	LEFT JOIN	Cat_SalaryClass csc
		ON		csc.ID = hwh.SalaryClassID
	LEFT JOIN	Cat_Position cp
		ON		cp.ID = hwh.PositionID
	LEFT JOIN	Cat_JobTitle cj
		ON		cj.ID = hwh.JobTitleID
	LEFT JOIN	Cat_WorkPlace cwp
		ON		cwp.ID = hwh.WorkPlaceID
	LEFT JOIN	Cat_NameEntity cne
		ON		cne.ID = hwh.EmployeeGroupID
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
				SELECT	TOP (1) aad.Available, aad.InitAvailable
				FROM	Att_AnnualDetail aad
				WHERE	aad.ProfileID = hwh.ProfileID
						AND	aad.Year = '+@Year+'
						AND aad.IsDelete IS NULL
						AND aad.Type =''E_ANNUAL_LEAVE''
				ORDER BY aad.MonthYear
				) aad2
	LEFT JOIn	#LenChinhThuc lct
		ON		lct.ProfileID = hwh.ProfileID 

	WHERE		hp.IsDelete is null
		AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart)
		AND		hp.DateHire <= @DateEnd
				'+ISNULL(@condition,'')+'
				'+ISNULL(@EmpStatus,'')+'
		--AND		hp.CodeEmp = ''20171121003''

'
SET @query2 =
'
	SELECT		hwh.ProfileID
				,E_BRANCH_CODE
				,E_DIVISION_CODE
				,E_DEPARTMENT_CODE	
				,aad.MonthYear, aad.LeaveInMonth
	INTO		#Att_AnnualDetail_Data
	FROM		#Infor_Hre_WorkHistory hwh
	LEFT JOIN	Att_AnnualDetail aad
		ON		aad.ProfileID = hwh.ProfileID
				AND	aad.Year = '+@Year+'
				AND aad.IsDelete IS NULL
				AND aad.Type =''E_ANNUAL_LEAVE''
				AND aad.MonthYear <= '''+@MonthYear+'''

	select		*
	INTO		#Att_Annual_Detail_Pivot
	from		(
				SELECT ProfileID,MonthYear,LeaveInMonth FROM #Att_AnnualDetail_Data
				) main
	PIVOT		( SUM(LeaveInMonth) for MonthYear in (' + @ListCol + ') ) as pv


	;WITH Results_Emp AS
	(
	select		hwh.*
				,'+@ListAlilas+'
				,'+@ListSumdata+' AS TotalUsedAnnual, ISNULL(RealYearlyAnnualLeave,0) - (  '+@ListSumdata+' ) AS RemainAnnualLeave
				,ROW_NUMBER() OVER ( ORDER BY DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp ) as RowNumber
				,@Year as "FYear"
				,@MonthYear as "MonthYear"
				,GETDATE() as "DateExport"
				,NULL AS "cos.OrderNumber",NULL AS "condi.EmploymentType",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID", NULL AS "hp.DateHire"
				,NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "condi.WorkPlaceID"
				,NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType"
				,NULL as "AnnualTransfer",NULL as "CheckData", NULL AS "PayPaidType"
	FROM		#Infor_Hre_WorkHistory hwh
	LEFT JOIN	#Att_Annual_Detail_Pivot aadp
		ON		hwh.ProfileID = aadp.ProfileID
	)
	SELECT		* 
	INTO		#Results
	FROM		Results_Emp
	WHERE		1 = 1 
				'+@AmountCondition+' '+@CheckData+'

	--SELECT * FROM #Infor_Hre_WorkHistory
	--SELECT * FROM #Att_AnnualDetail_Data

'
--rpt_Att_Annual_Detail

SET @query3 = '
	-- Lay du lieu Org
	select  
			' + @Top + '
			--newid() as ID
			MAX(OrgstructureID) as ID
			,cou.E_BRANCH_E
			,cou.E_DIVISION_E
			,cou.E_DEPARTMENT_E
			,coalesce(space(6) + cou.E_DEPARTMENT_E, space(3) + cou.E_DIVISION_E, cou.E_BRANCH_E) as OrgName
			,cou.E_BRANCH_CODE
			,concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE) as E_DIVISION_CODE
			,concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE + ''\'', cou.E_DEPARTMENT_CODE) as E_DEPARTMENT_CODE
			,CASE WHEN E_BRANCH_E IS NOT NULL AND E_DIVISION_E IS NULL THEN 0 ELSE 2 end  AS OrderNumDI
			,CASE WHEN E_BRANCH_E IS NOT NULL AND E_DIVISION_E IS NOT NULL AND cou.E_DEPARTMENT_E IS NULL THEN 0 ELSE 2 end  AS OrderNumDE
	into    #TbOrgUnit
	from    #NameEnglishORG_2 as cou
	--inner join (select ID, OrderNumber from Cat_OrgStructure where IsDelete is NULL AND ( Status IS NULL OR Status = ''E_APPROVED'' )) as cos on cos.ID = cou.OrgstructureID
	inner join (select ID, OrderNumber from Cat_OrgStructure where IsDelete is NULL) as cos on cos.ID = cou.OrgstructureID
	where   1 = 1
			AND cou.E_BRANCH_CODE NOT IN (''GD'')
			'+@OrderNumber+'
			--AND cou.E_BRANCH_E IN (''CORPORATE 1 DIVISION'')
	group by cou.E_BRANCH_E
			,cou.E_DIVISION_E
			,cou.E_DEPARTMENT_E
			,coalesce(space(6) + cou.E_DEPARTMENT_E, space(3) + cou.E_DIVISION_E, cou.E_BRANCH_E)
			,cou.E_BRANCH_CODE
			,concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE)
			,concat(cou.E_BRANCH_CODE + ''\'', cou.E_DIVISION_CODE + ''\'', cou.E_DEPARTMENT_CODE)
	print (''#TbOrgUnit'');

	DELETE #TbOrgUnit WHERE OrgName IS NULL OR E_BRANCH_E IS NULL OR E_BRANCH_E = ''''

	INSERT INTO #TbOrgUnit ( ID, E_BRANCH_E,E_DIVISION_E,E_DEPARTMENT_E, OrgName , E_BRANCH_CODE, E_DIVISION_CODE, E_DEPARTMENT_CODE,OrderNumDI, OrderNumDE )
	SELECT NEWID(),E_BRANCH_E,E_DIVISION_E,''Department/ Deputy Dept. Manager'',space(6) + ''Department/ Deputy Dept. Manager'',E_BRANCH_CODE,E_DIVISION_CODE,E_DEPARTMENT_CODE + ''DEPMANAGER'',2,1 FROM #TbOrgUnit WHERE E_BRANCH_E IS NOT NULL AND E_DIVISION_E IS NOT NULL AND E_DEPARTMENT_E IS NULL

	INSERT INTO #TbOrgUnit ( ID, E_BRANCH_E,E_DIVISION_E,E_DEPARTMENT_E, OrgName , E_BRANCH_CODE, E_DIVISION_CODE, E_DEPARTMENT_CODE,OrderNumDI,OrderNumDE )
	SELECT NEWID(),E_BRANCH_E,''Division/ Deputy Div. Manager/ Factory Manager'',NULL,space(3) + ''Division/ Deputy Div. Manager/ Factory Manager'',E_BRANCH_CODE,E_DIVISION_CODE + ''DIVIMANAGER'',E_DIVISION_CODE + ''DIVIMANAGER'',1,0 FROM #TbOrgUnit WHERE E_BRANCH_E IS NOT NULL AND E_DIVISION_E IS NULL AND E_DEPARTMENT_E IS NULL
 
	--INSERT INTO #TbOrgUnit ( ID, E_BRANCH_E,E_DIVISION_E,E_DEPARTMENT_E, OrgName , E_BRANCH_CODE, E_DIVISION_CODE, E_DEPARTMENT_CODE,OrderNumDI,OrderNumDE )
	--SELECT NEWID(),E_BRANCH_E,E_BRANCH_E + '' Total'',NULL,E_BRANCH_E + ''_ToTal'',E_BRANCH_CODE,E_DIVISION_CODE + ''TOTAL'',E_DIVISION_CODE + ''TOTAL'',3,0 FROM #TbOrgUnit WHERE E_BRANCH_E IS NOT NULL AND E_DIVISION_E IS NULL AND E_DEPARTMENT_E IS NULL
 
	 --select * from #TbOrgUnit hc order by hc.E_BRANCH_E,hc.OrderNumDI,hc.E_DIVISION_E,hc.OrderNumDE,hc.E_DEPARTMENT_E
 '

 SET @query4 ='
	-- 
	select  ID
			,E_BRANCH_E
			,E_DIVISION_E
			,E_DEPARTMENT_E
			,OrgName AS OrgStructureName
			--,coalesce(char (9) + char (9) + E_DEPARTMENT_E, char(9) + E_DIVISION_E, E_BRANCH_E) as OrgStructureName
			,' + @ListAlilas + '
			,OrderNumDI, OrderNumDE
	into    #Att_Annual_Org1
	from    (select tou.*
				  , yo.MonthYear
				  , case when tou.E_DIVISION_E is null and tou.E_DEPARTMENT_E is null then Branch.LeaveInMonth
						 when tou.E_DEPARTMENT_E is null then Division.LeaveInMonth
						 else Department.LeaveInMonth
					end as LeaveInMonth
			 from   #TbOrgUnit as tou
					cross apply @YearOT as yo
					cross apply (select sum(aadd.LeaveInMonth) as LeaveInMonth
								 from	#Att_AnnualDetail_Data aadd
								 where  aadd.E_BRANCH_CODE = tou.E_BRANCH_CODE
										and aadd.MonthYear = yo.MonthYear
										AND exists ( select r.ProfileID from #Results r where r.ProfileID = aadd.ProfileID )
								) as Branch
					cross apply (select sum(aadd.LeaveInMonth) as LeaveInMonth
								 from  #Att_AnnualDetail_Data aadd
								 where  ( aadd.E_DIVISION_CODE = tou.E_DIVISION_CODE
										OR aadd.E_DIVISION_CODE +''DIVIMANAGER'' = tou.E_DIVISION_CODE )
										and aadd.MonthYear = yo.MonthYear
										AND exists ( select r.ProfileID from #Results r where r.ProfileID = aadd.ProfileID )
								) as Division
					cross apply (select sum(aadd.LeaveInMonth) as LeaveInMonth
								 from   #Att_AnnualDetail_Data aadd
								 where  ( aadd.E_DEPARTMENT_CODE = tou.E_DEPARTMENT_CODE
										OR aadd.E_DEPARTMENT_CODE +''DEPMANAGER'' = tou.E_DEPARTMENT_CODE )
										and aadd.MonthYear = yo.MonthYear
										AND exists ( select r.ProfileID from #Results r where r.ProfileID = aadd.ProfileID )
								) as Department
			) as DataAN pivot ( sum(LeaveInMonth) for MonthYear in (' + @ListCol + ') ) as pv;
	print (''#Att_Annual_Org1'');
 
	 --select * from #Att_Annual_Org1 hc order by hc.E_BRANCH_E,hc.OrderNumDI,hc.E_DIVISION_E,hc.OrderNumDE,hc.E_DEPARTMENT_E

	select		tou.ID
				,case when tou.E_DIVISION_E is null and tou.E_DEPARTMENT_E is null then Branch.RealYearlyAnnualLeave
				when tou.E_DEPARTMENT_E is null then Division.RealYearlyAnnualLeave
				else Department.RealYearlyAnnualLeave
				end as RealYearlyAnnualLeave
				,case when tou.E_DIVISION_E is null and tou.E_DEPARTMENT_E is null then Branch.TotalUsedAnnual
				when tou.E_DEPARTMENT_E is null then Division.TotalUsedAnnual
				else Department.TotalUsedAnnual
				end as TotalUsedAnnual				
				,case when tou.E_DIVISION_E is null and tou.E_DEPARTMENT_E is null then Branch.RemainAnnualLeave
				when tou.E_DEPARTMENT_E is null then Division.RemainAnnualLeave
				else Department.RemainAnnualLeave
				end as RemainAnnualLeave
	INTO		#Att_Annual_Org2
	from		#TbOrgUnit as tou
	OUTER apply (select		sum(ihwh.RealYearlyAnnualLeave) as RealYearlyAnnualLeave, sum(ihwh.TotalUsedAnnual) as TotalUsedAnnual, sum(ihwh.RemainAnnualLeave) as RemainAnnualLeave
					from	#Results ihwh
					where	ihwh.E_BRANCH_CODE = tou.E_BRANCH_CODE
				) as Branch
	OUTER apply (select		sum(ihwh.RealYearlyAnnualLeave) as RealYearlyAnnualLeave, sum(ihwh.TotalUsedAnnual) as TotalUsedAnnual, sum(ihwh.RemainAnnualLeave) as RemainAnnualLeave
					from	#Results ihwh
					where	( ihwh.E_DIVISION_CODE = tou.E_DIVISION_CODE
							OR ihwh.E_DIVISION_CODE +''DIVIMANAGER'' = tou.E_DIVISION_CODE )
				) as Division
	OUTER apply (select		sum(ihwh.RealYearlyAnnualLeave) as RealYearlyAnnualLeave, sum(ihwh.TotalUsedAnnual) as TotalUsedAnnual, sum(ihwh.RemainAnnualLeave) as RemainAnnualLeave
					from	#Results ihwh
					where	( ihwh.E_DEPARTMENT_CODE = tou.E_DEPARTMENT_CODE
							OR ihwh.E_DEPARTMENT_CODE +''DEPMANAGER'' = tou.E_DEPARTMENT_CODE )
				) as Department

	SELECT		aao1.*, aao2.RealYearlyAnnualLeave, aao2.TotalUsedAnnual, aao2.RemainAnnualLeave, CASE WHEN aao2.RealYearlyAnnualLeave > 0 THEN ROUND(aao2.TotalUsedAnnual / aao2.RealYearlyAnnualLeave * 100,2) ELSE 0 END AS Ratio, ROW_NUMBER() OVER ( ORDER BY E_BRANCH_E,OrderNumDI,E_DIVISION_E,OrderNumDE,E_DEPARTMENT_E ) as RowNumber
				,CASE WHEN E_DEPARTMENT_E IS NULL THEN
					CASE
					WHEN E_DIVISION_E IS NULL AND E_BRANCH_E IS NULL THEN 0 
					WHEN E_DIVISION_E IS NULL AND E_BRANCH_E IS NOT NULL THEN 1
					WHEN E_DIVISION_E IS NOT NULL AND E_BRANCH_E IS NOT NULL THEN 2
					END
				ELSE 3 END AS ConditionFormat
				,@Year as "FYear"
				,@MonthYear as "MonthYear"
				,GETDATE() as "DateExport"
	INTO		#Results_Org
	FROM		#Att_Annual_Org1 aao1
	INNER JOIN	#Att_Annual_Org2 aao2
		ON		aao1.ID = aao2.ID

	SELECT	SUM(RealYearlyAnnualLeave) AS SUM_RealYearlyAnnualLeave
			,SUM(Data1) AS SUM_Data1,SUM(Data2) AS SUM_Data2,SUM(Data3) AS SUM_Data3,SUM(Data4) AS SUM_Data4,SUM(Data5) AS SUM_Data5,SUM(Data6) AS SUM_Data6
			,SUM(Data7) AS SUM_Data7,SUM(Data8) AS SUM_Data8,SUM(Data9) AS SUM_Data9,SUM(Data10) AS SUM_Data10,SUM(Data11) AS SUM_Data11,SUM(Data12) AS SUM_Data12
			, SUM(TotalUsedAnnual) AS SUM_TotalUsedAnnual, SUM(RemainAnnualLeave) AS SUM_RemainAnnualLeave, SUM(Ratio) AS SUM_Ratio
	INTO	#SUM_Results_Org
	FROM	#Results_Org
	WHERE	E_BRANCH_E IS NOT NULL AND E_DIVISION_E IS NOT NULL AND E_DEPARTMENT_E IS NULL

 '

set @queryPageSize = ' 
	ALTER TABLE #Results ADD TotalRow int
	ALTER TABLE #Results_Org ADD TotalRow int

	declare @totalRow int

	SELECT @totalRow = COUNT(*) FROM #Results
	update #Results set TotalRow = @totalRow

	SELECT @totalRow = COUNT(*) FROM #Results_Org
	update #Results_Org set TotalRow = @totalRow

	SELECT		RowNumber AS STT,*
	FROM		#Results 
	WHERE		RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
	ORDER BY	RowNumber

	SELECT		RowNumber AS STT,*
	FROM		#Results_Org
	WHERE		RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
	ORDER BY	RowNumber

	-- Sum
	SELECT		Top(1) * 
	FROM		#SUM_Results_Org 

	DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG, #NameEnglishORG_2
	DROP TABLE #tblPermission, #Hre_WorkHistory,#LenChinhThuc, #Infor_Hre_WorkHistory, #Att_AnnualDetail_Data, #Att_Annual_Detail_Pivot, #Results, #TbOrgUnit, #Att_Annual_Org1, #Att_Annual_Org2, #Results_Org, #SUM_Results_Org
	
	'

DECLARE @Strlang VARCHAR(5) = CAST(@LanguageID AS CHAR(1));  
IF (@LanguageID > 0  AND EXISTS   
	(  
	SELECT 1  
	FROM dbo.Sys_AllSetting  
	WHERE IsDelete IS NULL  
	AND Name = 'HRM_SYS_CATEGORYTRANSLATIONCONFIGURATION'  
	AND Value1 = 'True'  
	)
)
 
BEGIN  
DECLARE @queryWhereLang NVARCHAR(MAX) = @Query;  
BEGIN TRY  

SELECT		ColumnName, TableDefault, TableTranslate  
INTO		#TableColumnTranslate  
FROM		dbo.View_GetTableTranslate

SELECT		ColumnName, TableDefault, TableTranslate  
INTO		#tblTempTranslate  
FROM		#TableColumnTranslate  
WHERE		@Query LIKE '%' + TableDefault + '%'
	AND		TableDefault <> 'Cat_EnumTranslate'

DECLARE @strCondition VARCHAR(MAX) = NULL;  
DECLARE @strConditionTranslate VARCHAR(500) = NULL;  

WHILE (EXISTS (SELECT 1 FROM #tblTempTranslate))  
BEGIN  
DECLARE @i VARCHAR(100) =  
( SELECT TOP (1) TableDefault FROM #tblTempTranslate 
)

SET @strCondition = NULL;  
SET @strConditionTranslate = NULL;  

SELECT		@strConditionTranslate = COALESCE(@strConditionTranslate + ',', '') + cb.ColumnName  
FROM		#tblTempTranslate cb  
WHERE		cb.TableDefault = @i;

SET	@strCondition = 'ID, ISNULL(ColumnCustom.' + @strConditionTranslate + ', ColumnDefault.'+@strConditionTranslate+') AS '+@strConditionTranslate+',IsDelete'

--- Lay ít cột cho đỡ rối, nếu cần cột thêm thì làm tương tự bên dưới IF

IF @i = 'Cat_OrgStructure'
BEGIN
SET @strCondition += ', OrderNumber '
END

DECLARE @sqlQueryCustom VARCHAR(MAX)  

SET @sqlQueryCustom= N' 
(
SELECT	'+ @strCondition + N' 
FROM	dbo.' + @i + ' ColumnDefault WITH(NOLOCK) 
LEFT JOIN (SELECT OriginID, ' + @strConditionTranslate+ ' FROM dbo.' + @i + '_Translate WHERE IsDelete IS NULL AND LanguageID = ' +@Strlang+ ' ) ColumnCustom 
	ON	ColumnCustom.OriginID = ColumnDefault.ID WHERE ColumnDefault.IsDelete IS null 
) ';  
SET @Query = ( SELECT dbo.RegexReplaceTable(@Query, @i, @sqlQueryCustom) );  

DELETE #tblTempTranslate  
WHERE TableDefault = @i;  
END;  
DROP TABLE #tblTempTranslate,  
#TableColumnTranslate;  
END TRY  
BEGIN CATCH  
SET @Query = @queryWhereLang; 
END CATCH; 
END;  


exec( @getdata +@query + @query2 + @query3 + @query4 + @queryPageSize )


print (@getdata)

Set @Query = replace(replace(@Query, char(13) + char(10), char(10)), char(13), char(10));
while len(@Query) > 1
	begin
		if charindex(char(10), @Query) between 1 and 4000
			begin
                    set @CurrentEnd = charindex(char(10), @Query) - 1;
                    set @Offset = 2;
			end;
		else
			begin
                    set @CurrentEnd = 4000;
                    set @Offset = 1;
		end;   
			print substring(@Query, 1, @CurrentEnd); 
			set @Query = substring(@Query, @CurrentEnd + @Offset, len(@Query));   
	end;

print (@query2)
print (@query3)
print (@query4)
print (@queryPageSize)

END
--rpt_Att_Annual_Detail
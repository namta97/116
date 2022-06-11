---Nam Ta: 17/12/2021: Tro cap truc tet
ALTER proc rpt_WorkingOnLunarNewYear
@condition nvarchar(max) = " and (WorkDateRoot between '2022-01-31' and '2022-02-04' ) and (MoneyPerDay = 400000 ) ",
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
			SET @condition =  '  and (WorkDateRoot between ''2021-09-01'' and ''2021-09-10'' ) and (MoneyPerDay = 400000 )  '
	end;

----Condition---
DECLARE @EmpStatus VARCHAR(300) = ''
DECLARE @MoneyPerDay VARCHAR(200) = '400000'
DECLARE @DayNumber VARCHAR(500) = ''
DECLARE @WorkDateRoot VARCHAR(500) = ''


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

	set @index = 0

	set @index = 0
	set @index = charindex('(OrderNumber ','('+@tempID,0) 
	if(@index > 0)
	begin
		set @condition = REPLACE(@condition,'(OrderNumber ','(cos.OrderNumber ')
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

	SET @index = CHARINDEX('(condi.SalaryClassID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.SalaryClassID ','(aop.SalaryClassID ')
	END

	SET @index = CHARINDEX('(condi.PositionID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.PositionID ','(aop.PositionID ')
	END
	
	SET @index = CHARINDEX('(condi.JobTitleID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.JobTitleID ','(aop.JobTitleID ')
	END
	
	SET @index = CHARINDEX('(condi.WorkPlaceID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.WorkPlaceID ','(aop.WorkPlaceID ')
	END
	
	SET @index = CHARINDEX('(condi.EmployeeGroupID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.EmployeeGroupID ','(aop.EmployeeGroupID ')
	END
		
	SET @index = CHARINDEX('(condi.LaborType ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.LaborType ','(aop.LaborType ')
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

	SET @index = charindex('(WorkDateRoot ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		SET @WorkDateRoot = @TempCondition
	END

	SET @index = charindex('(DayNumber ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		SET @DayNumber = @TempCondition
	END
        
	SET @index = charindex('(MoneyPerDay ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		SET @MoneyPerDay = REPLACE(@TempCondition ,' ','') 
		SET @MoneyPerDay = REPLACE(@MoneyPerDay ,')','') 
		SET @MoneyPerDay = REPLACE(@MoneyPerDay ,'and(MoneyPerDay=','') 
	END

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1
END

--rpt_WorkingOnLunarNewYear
Declare @DateStart Date
Declare @DateEnd DATE
Declare @DateEndVarchar VARCHAR(50) = ''

SET @DateEnd = RIGHT(REPLACE(REPLACE(REPLACE(@WorkDateRoot,' ',''),')',''),'''',''),10)
SET @DateEndVarchar = RIGHT(REPLACE(REPLACE(REPLACE(@WorkDateRoot,' ',''),')',''),'''',''),10)
SET @DateStart = RIGHT(REPLACE(REPLACE(REPLACE(REPLACE(@WorkDateRoot,' ',''),')',''),'''',''),'and'+@DateEndVarchar,''),10)



declare @Count int = 1;
declare @ListCol varchar(max);
DECLARE @ListAlilas varchar(max);

declare @FirstDay date = @DateStart;
while @FirstDay <= @DateEnd
        begin
            set @ListCol = coalesce(@ListCol + ',', '') + quotename(@FirstDay);
            set @ListAlilas = coalesce(@ListAlilas + ',', '') + quotename(@FirstDay) + ' as Day' + convert(varchar(10), @Count);
            set @FirstDay = dateadd(day, 1, @FirstDay);
            set @Count += 1;
        end;


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

-- Export
DECLARE @GetData varchar(max)
DECLARE @query nvarchar(max)
DECLARE @query1 varchar(max)
DECLARE @queryPageSize varchar(max)


set @GetData = '

    declare @DateStart date = ''' + convert(varchar(20), @DateStart, 111) + '''
    declare @DateEnd date = ''' + convert(varchar(20), @DateEnd, 111) + '''

	CREATE TABLE #tblPermission (id uniqueidentifier primary key )
	INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'

	select s.* into #Hre_Profile from Hre_Profile s join #tblPermission tb on s.ID = tb.ID
	where isdelete is null 

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
	'
set @query = ' 
	-----------------------Lay du lieu ---------------------------

	SELECT		' +@Top+ '
				aop.ProfileID,hp.CodeEmp,hp.ProfileName,neorg.DivisionName,neorg.CenterName,neorg.DepartmentName,neorg.SectionName,neorg.UnitName
				,csct.SalaryClassName, cwptl.WorkPlaceName,aop.WorkDateRoot, aop.RegisterHours, NULL AS DayNumber
	INTO		#Att_OvertimePlan
	FROM		Att_OvertimePlan aop
	INNER JOIN	#Hre_Profile hp
		ON		hp.ID = aop.ProfileID
	LEFT JOIN	Cat_OrgStructure cos 
		ON		cos.ID = aop.OrgStructureID
	LEFT JOIN	#NameEnglishORG neorg 
		ON		neorg.OrgStructureID = aop.OrgStructureID
	LEFT JOIN	Cat_SalaryClass_Translate csct
		ON		csct.OriginID = aop.SalaryClassID
	LEFT JOIN	Cat_WorkPlace_Translate cwptl
		ON		cwptl.OriginID = aop.WorkPlaceID
	LEFT JOIN	Cat_NameEntity_Translate cnet
		ON		cnet.OriginID = aop.EmployeeGroupID
	LEFT JOIN	Cat_Position_Translate cptl
		ON		cptl.OriginID = aop.PositionID
	LEFT JOIN	Cat_JobTitle_Translate cjttl
		ON		cjttl.OriginID = aop.JobTitleID
	OUTER APPLY (
				SELECT	TOP(1) cetl.EN, cetl.VN
				FROM	Cat_EnumTranslate cetl
				WHERE	cetl.EnumKey = aop.LaborType 
						AND cetl.EnumName = ''LaborType'' AND cetl.IsDelete is null
				ORDER BY DateUpdate DESC
				) cetl2

	WHERE		aop.IsDelete is null
		AND		aop.Status = ''E_APPROVED''
		AND		exists (Select * from #tblPermission tpm where id = hp.id )
				'+ISNULL(@condition,'')+'
				'+ISNULL(@EmpStatus,'')+'

'
SET @query1 ='
	----Dem so ngay co OT

	SELECT		ProfileID, COUNT(DISTINCT WorkDateRoot) as DayNumber
	INTO		#Count_DayNumber
	FROM		#Att_OvertimePlan
	WHERE		RegisterHours IS NOT NULL
	GROUP BY	ProfileID,CodeEmp,ProfileName,DivisionName,CenterName,DepartmentName,SectionName,UnitName,SalaryClassName, WorkPlaceName


	---Pivot data
	SELECT		ProfileID,CodeEmp,ProfileName,DivisionName,CenterName,DepartmentName,SectionName,UnitName,SalaryClassName, WorkPlaceName
				,' + @ListAlilas + '
	INTO		#Result
	FROM		#Att_OvertimePlan
	PIVOT		( SUM(RegisterHours) FOR WorkDateRoot IN ( '+@ListCol+' )) AS D

	--- GET ALL

	SELECT		s.*, cd.DayNumber,cd.DayNumber * '+@MoneyPerDay+' AS Amount,'+@MoneyPerDay+' AS MoneyPerDay
				,ROW_NUMBER() OVER ( ORDER BY  DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, SalaryClassName,CodeEmp ) AS RowNumber
				,@DateStart AS DateStart
				,GETDATE() AS DateExport
				,NULL AS "cos.OrderNumber",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "condi.WorkPlaceID"
				,NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType", NULL AS "condi.EmpStatus"
				,NULL AS WorkDateRoot
	INTO		#Results
	FROM		#Result s
	LEFT JOIN	#Count_DayNumber cd
	ON			s.ProfileID = cd.ProfileID
	WHERE		1 = 1 '+@DayNumber+'

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
	drop table #Hre_Profile
	DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG,#Att_OvertimePlan, #Result, #Count_DayNumber


	'
PRINT (@GetData)
PRINT (@query)
PRINT (@query1)
PRINT (@queryPageSize )

EXEC ( @GetData +@query + @query1 + @queryPageSize )


END
--rpt_WorkingOnLunarNewYear
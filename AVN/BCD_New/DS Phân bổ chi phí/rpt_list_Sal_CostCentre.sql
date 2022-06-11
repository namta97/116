---Nam Ta: 4/8/2021: DS Phan bo chi phi
ALTER proc rpt_list_Sal_CostCentre	
@condition NVARCHAR(MAX) = " and (MonthYear = '2022-02-01') ",
@PageIndex INT = 1,
@PageSize INT = 10000,
@Username VARCHAR(100) = 'khang.nguyen'
AS
BEGIN

DECLARE @str NVARCHAR(MAX)
DECLARE @countrow INT
DECLARE @row INT
DECLARE @index INT
DECLARE @ID NVARCHAR(500)
DECLARE @TempID NVARCHAR(MAX)
DECLARE @TempCondition NVARCHAR(MAX)
DECLARE @Top VARCHAR(20) = ' '

IF LTRIM(RTRIM(@Condition)) = '' OR @Condition IS NULL
BEGIN
		SET @Top = ' top 0 ';
		SET @condition =  ' and (MonthYear = ''2022-02-01'') '
END;

----Condition----
DECLARE @MonthYearCondition VARCHAR(100) = ' '
DECLARE @EmpStatus nvarchar(300) = ''
DECLARE @RateShare varchar(300) = ''
DECLARE @DateEffect varchar(300) = ''

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
	set @index = charindex('MonthYear = ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		--set @condition = REPLACE(@condition,'and (MonthYear = ','')
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		SET @MonthYearCondition = @TempCondition	
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

	SET @index = CHARINDEX('(condi.CostCentreID ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
     	SET @condition = REPLACE(@condition,'(condi.CostCentreID ','(hwh.CostCentreID ')
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

	SET @index = CHARINDEX('(PayPaidType ','('+@tempID,0) 
	IF(@index > 0)
	BEGIN
		SET @TempCondition = 'AND ('+@tempID
		SET @condition = REPLACE(@condition,@TempCondition,'')
	END

	SET @index = charindex('(AmountCondition ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
	END
        
	SET @index = charindex('(RateShare ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		SET @RateShare = REPLACE(@TempCondition ,'RateShare','lecs.RateShare') 
	END

	SET @index = charindex('(DateEffect ','('+@tempID,0) 
	if(@index > 0)
	BEGIN
		set @TempCondition = 'and ('+@tempID
		set @condition = REPLACE(@condition,@TempCondition,'')
		SET @DateEffect = REPLACE(@TempCondition ,'and (','(') 
	END

	DELETE #tableTempCondition WHERE ID = @ID
	set @row = @row - 1
END

-- Export

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


--- DK ngay hieu luc
IF (@DateEffect is not null and @DateEffect <> '')
BEGIN
SET @DateEffect = ' AND ' + REPLACE(@DateEffect,'DateEffect','lecs.DateEffectFrom') + ' OR ' + REPLACE(@DateEffect,'DateEffect','lecs.DateEffectTo')
END

DECLARE @GetData varchar(max)
DECLARE @query nvarchar(max)
DECLARE @UnionData VARCHAR(max)
DECLARE @UpdateData VARCHAR(max)
DECLARE @queryPageSize varchar(max)


set @GetData = '

	CREATE TABLE #tblPermission (id uniqueidentifier primary key )
	INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Hre_Profile'''+'


	select s.* into #Hre_Profile from Hre_Profile s join #tblPermission tb on s.ID = tb.ID
	where isdelete is null -- '+@MonthYearCondition+'

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
	-----------------------Lay du lieu ---------------------------
	;WITH List_emp_costcentre_root AS
	(
	SELECT		' +@Top +'
				hp.ID AS ProfileID, hwh.ID AS WorkHistoryID
				,cou.E_BRANCH AS DivisionName, cou.E_UNIT AS CenterName, cou.E_DIVISION AS DepartmentName, cou.E_DEPARTMENT AS SectionName, cou.E_TEAM AS UnitName
				,hwh.CostcentreID, cost.Code AS CostCentreCode, cne.Code AS Group_CostCentreCode
	FROM		Hre_Profile hp
	LEFT JOIN	#Hre_WorkHistory hwh
		ON		hp.ID = hwh.ProfileID 
	LEFT JOIN	Cat_OrgStructure cos 
		ON		cos.ID = hwh.OrganizationStructureID
	LEFT JOIN	Cat_OrgUnit cou
		ON		cou.OrgstructureID = hwh.OrganizationStructureID
	LEFT JOIN	Cat_CostCentre cost
		ON		cost.ID = hwh.CostcentreID
	LEFT JOIN	Cat_SalaryClass csc
		ON		csc.ID = hwh.SalaryClassID
	LEFT JOIN	Cat_AbilityTile cat
		ON		cat.ID = csc.AbilityTitleID
	LEFT JOIN	Cat_NameEntity cne
		ON		cne.ID = cost.CostCentreGroupID
	WHERE		hp.IsDelete IS NULL
		AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart )
		AND		hp.DateHire <= @DateEnd
		AND		exists (Select * from #tblPermission tpm where id = hp.id )
				'+ISNULL(@condition,'')+'
				'+ISNULL(@EmpStatus,'')+'
		
	)

	Select		lec.ProfileID,lec.WorkHistoryID, lec.DivisionName, lec.CenterName,lec.DepartmentName, lec.SectionName,lec.UnitName, lec.CostCentreCode, lec.Group_CostCentreCode
				,cou.E_BRANCH AS DivisionName_Share, cou.E_UNIT AS CenterName_Share, cou.E_DIVISION AS DepartmentName_Share, cou.E_DEPARTMENT AS SectionName_Share, cou.E_TEAM AS UnitName_Share
				,lec.CostCentreCode AS CostCentreCode_Share, lec.Group_CostCentreCode Group_CostCentreCode_Share
				,CONVERT(DECIMAL(12,2),1) AS RateShare, NULL AS DateEffectFrom, NULL AS DateEffectTo, 0 As LevelRoot
	INTO		#List_emp_costcentre_root
	FROM		List_emp_costcentre_root lec
	LEFT JOIN	#OrgSplitCost osc
		ON		osc.CostCentreID = lec.CostCentreID
	LEFT JOIN	Cat_OrgUnit cou
		ON		cou.OrgstructureID = osc.OrgstructureID
	
'
SET @UnionData =
'	
	SELECT		lecr.*, 0 AS IsDuplicate, NULL AS STT
	INTO		#List_emp_costcentre_share
	FROM		#List_emp_costcentre_root lecr
	UNION
				( 
				SELECT		' +@Top + '
							sccs.ProfileID,lec.WorkHistoryID,lec.DivisionName, lec.CenterName,lec.DepartmentName, lec.SectionName,lec.UnitName,lec.CostCentreCode, lec.Group_CostCentreCode
							,cou.E_BRANCH AS DivisionName_Share, cou.E_UNIT AS CenterName_Share ,cou.E_DIVISION AS DepartmentName_Share , cou.E_DEPARTMENT AS SectionName_Share ,cou.E_TEAM AS UnitName_Share
							,cost.Code AS CostCentreCode_Share, cne.Code AS Group_CostCentreCode_Share
							,CONVERT(DECIMAL(12,2),sccs.Rate/100) AS RateShare, sccs.DateStart AS DateEffectFrom, sccs.DateEnd AS  DateEffectTo
							,ROW_NUMBER() OVER(PARTITION BY sccs.ProfileID ORDER BY sccs.Rate DESC) AS LevelRoot,CASE WHEN cost.Code = lec.CostCentreCode THEN 1 ELSE 0 END AS IsDuplicate, NULL AS STT
				FROM		Sal_CostCentreSal sccs
				LEFT JOIN	Cat_OrgUnit Cou
					ON		Cou.OrgstructureID = sccs.OrgStructureID
				LEFT JOIN	Cat_CostCentre cost
					ON		cost.ID = sccs.CostcentreID
				LEFT JOIN	Cat_NameEntity cne
					ON		cne.ID = cost.CostCentreGroupID
				INNER JOIN	#List_emp_costcentre_root lec
					ON		lec.ProfileID = sccs.ProfileID
				WHERE		sccs.DateStart <= @DateEnd AND ( sccs.DateEnd >= @DateStart OR sccs.DateEnd IS NULL )
							AND sccs.IsDelete IS NULL
				)

	SELECT		lecs.STT,lecs.ProfileID,hp.CodeEmp, hp.ProfileName
				,lecs.DivisionName, lecs.CenterName,lecs.DepartmentName, lecs.SectionName,lecs.UnitName
				,csc.Code AS SalaryClassCode, csc.SalaryClassName, cp.PositionName, cjt.JobTitleName,cetl.VN AS EmploymentType,cetl2.VN AS LaborType,cne.NameEntityName AS EmployeeGroupName, cwp.WorkPlaceName, hp.DateHire, hp.DateQuit,hp.DateEndProbation
				,cat.Code AS CostTypeCode,lecs.CostCentreCode, lecs.Group_CostCentreCode
				,@StartMonth AS "MonthYear"
				,lecs.DivisionName_Share, lecs.CenterName_Share, lecs.DepartmentName_Share, lecs.SectionName_Share, lecs.UnitName_Share,csc.Code AS SalaryClassCode_Share, csc.SalaryClassName AS SalaryClassName_Share, cat.Code AS CostTypeCode_Share
				,lecs.CostCentreCode_Share, lecs.Group_CostCentreCode_Share, lecs.RateShare, lecs.DateEffectFrom, lecs.DateEffectTo,lecs.LevelRoot, 1 AS IsDisPlay, 0 AS IsErrorData, IsDuplicate 
				,ROW_NUMBER() OVER ( ORDER BY  lecs.DivisionName, lecs.CenterName,lecs.DepartmentName, lecs.SectionName ,cwp.WorkPlaceName,lecs.UnitName, cne.NameEntityName, cetl2.VN , csc.SalaryClassName, cetl.VN,hp.CodeEmp,lecs.LevelRoot ) as RowNumber
				, GETDATE() AS DateExport
				,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "condi.EmploymentType",NULL AS "condi.SalaryClassID" ,NULL AS "condi.PositionID", NULL AS "condi.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit"
				,NULL AS "condi.WorkPlaceID",NULL AS "condi.EmployeeGroupID", NULL AS "condi.LaborType", NULL AS "condi.CostCentreID", NULL AS "csc.AbilityTitleID", NULL AS "cost.CostCentreGroupID"
				,NULL AS "condi.EmpStatus",NULL AS "GroupCostCentre", NULL AS "DateEffect"
	INTO		#Results
	FROM		#List_emp_costcentre_share lecs
	LEFT JOIN	#Hre_WorkHistory hwh
		ON		hwh.ID = lecs.WorkHistoryID
	INNER JOIN	Hre_Profile hp
		ON		hp.ID = hwh.ProfileID 
	LEFT JOIN	Cat_SalaryClass csc
		ON		csc.ID = hwh.SalaryClassID
	LEFT JOIN	Cat_AbilityTile cat
		ON		cat.ID = csc.AbilityTitleID
	LEFT JOIN	Cat_Position cp
		ON		cp.ID = hwh.PositionID
	LEFT JOIN	Cat_JobTitle cjt
		ON		cjt.ID = hwh.JobTitleID
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

	WHERE 1 = 1 '+@RateShare+' '+@DateEffect+'

'

SET @UpdateData=
'	
	--- dong goc : LevelRoot = 0, hien thi isdisplay = 1

	---Tinh tong Phan bo cua tung nguoi
	SELECT		ProfileID, Sum(RateShare) AS SumRateShare
	INTO		#SumRateShare
	FROM		#Results
	WHERE		LevelRoot <> 0
	GROUP BY	ProfileID

	------Update lai rate cho dong thong tin goc
	--UPDATE		r
	--SET			r.RateShare =  CASE WHEN 1 - ISNULL(s.SumRateShare,0) > 0 THEN 1 - ISNULL(s.SumRateShare,0) ELSE 0 END
	--FROM		#Results r
	--INNER JOIN	#SumRateShare s
	--	ON		r.ProfileID = s.ProfileID
	--WHERE		r.LevelRoot = 0

	----Update lai rate cho dong thong tin goc
	UPDATE		r
	SET			r.RateShare = 1 - ISNULL(s.SumRateShare,0)
	FROM		#Results r
	INNER JOIN	#SumRateShare s
		ON		r.ProfileID = s.ProfileID
	WHERE		r.LevelRoot = 0

	--- upadte toan bo dong phan bo IsDisPlay = 0 khi dong thong tin goc co rate > 0
	UPDATE		#Results
	SET			IsDisPlay = 0
	WHERE		ProfileID IN 
				( SELECT ProfileID FROM #Results WHERE LevelRoot = 0 AND RateShare <> 0)
				AND LevelRoot <> 0

	---- update dong phan bo thu 3 tro len IsDisPlay = 0 khi dong goc = 0
	UPDATE		#Results
	SET			IsDisPlay = 0
	WHERE		ProfileID IN 
				( SELECT ProfileID FROM #Results WHERE LevelRoot = 0 AND RateShare = 0)
				AND LevelRoot > 1

	---- Xoa dong goc neu Rate = 0
	DELETE		#Results WHERE LevelRoot = 0 AND RateShare = 0

	---- Update IsErrorData = 1 khi SumRateShare > 1
	UPDATE		#Results
	SET			IsErrorData = 1
	WHERE		ProfileID IN 
				( SELECT ProfileID FROM #SumRateShare WHERE SumRateShare > 1)

	---- Tao STT ngoai tru dong NULL
	SELECT		RowNumber,ROW_NUMBER() OVER ( ORDER BY  DivisionName, CenterName,DepartmentName, SectionName ,WorkPlaceName, UnitName, EmployeeGroupName, LaborType, SalaryClassName, EmploymentType,CodeEmp,LevelRoot ) AS STT2
	INTO		#TempSTT
	FROM		#Results
	WHERE		IsDisPlay = 1


	UPDATE		r
	SET			r.STT = temp.STT2
	FROM		#Results r
	INNER JOIN	#TempSTT temp 
		ON		r.RowNumber = temp.RowNumber
		
		
	'
set @queryPageSize = ' 

	ALTER TABLE #Results ADD TotalRow int
	declare @totalRow int
	SELECT @totalRow = COUNT(*) FROM #Results
	update #Results set TotalRow = @totalRow


	SELECT		* 
	FROM		#Results
	WHERE		RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
	ORDER BY	RowNumber


	DROP TABLE #Results
	drop table #tblPermission
	drop table #Hre_Profile, #Hre_WorkHistory
	DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG
	DROP TABLE #List_emp_costcentre_root, #List_emp_costcentre_share, #SumRateShare,#TempSTT,#OrgSplitCost

	'
print ( @GetData)
PRINT( @query)
PRINT( @UnionData)
PRINT(@UpdateData)
PRINT(@queryPageSize )

exec( @GetData +@query + @UnionData + @UpdateData + @queryPageSize )


END
--rpt_list_Sal_CostCentre

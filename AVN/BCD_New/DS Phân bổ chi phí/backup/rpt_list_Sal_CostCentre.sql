
ALTER proc [rpt_list_Sal_CostCentre]	
@condition nvarchar(max) = " and (MonthYear = '2021-04-01') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'hanh.nguyen'
as
begin

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
	DECLARE @EmStatus nvarchar(300) = ''
-- cat dieu kien

	
	while @row > 0
	begin
			set @index = 0
			set @ID = (select top 1 ID from #tableTempCondition)
			set @tempID = replace(@ID,'@',',')

			set @index = 0
			set @index = charindex('MonthYear = ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				--set @condition = REPLACE(@condition,'and (MonthYear = ','')
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @MonthYear = @tempCodition	
			end

			set @index = charindex('(GroupBank ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
			END
            
			set @index = charindex('(BankName ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
			END

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

			set @index = charindex('(EmpStatus ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @EmStatus = REPLACE(@tempCodition,'(EmpStatus IN ','')
				set @EmStatus = REPLACE(@EmStatus,',',' OR ')
				set @EmStatus = REPLACE(@EmStatus,'))',')')
			END

			set @index = charindex('(PayPaidType ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'AND ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
			END

			SET @index = charindex('(AmountCondittion ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'and ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
			END
            
			set @index = charindex('(IsSalary ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'AND ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
			END

			set @index = charindex('(IsNotSalary ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'AND ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
			END

			set @index = charindex('(IsSalaryBanking ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'AND ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
			END


			DELETE #tableTempCondition WHERE ID = @ID
			set @row = @row - 1
			END

-- Export

---DK trang thai nhan vien
IF (@EmStatus is not null and @EmStatus != '')
BEGIN
	SET @index = charindex('E_PROFILE_NEW',@EmStatus,0) 
	IF(@index > 0)
	BEGIN
	SET @EmStatus = REPLACE(@EmStatus,'''E_PROFILE_NEW''',' (hp.DateHire <= @DateEnd AND hp.DateHire >= @DateStart ) ')
	END
	SET @index = charindex('E_PROFILE_ACTIVE',@EmStatus,0) 
	IF(@index > 0)
	BEGIN
	SET @EmStatus = REPLACE(@EmStatus,'''E_PROFILE_ACTIVE''','(hp.DateQuit IS NULL OR hp.DateQuit >= @DateEnd)')
	END
	SET @index = charindex('E_PROFILE_QUIT',@EmStatus,0) 
	IF(@index > 0)
	BEGIN
	SET @EmStatus = REPLACE(@EmStatus,'''E_PROFILE_QUIT''',' (hp.DateQuit <= @DateEnd AND hp.DateQuit >= @DateStart) ')	
	END
END



	DECLARE @GetData nvarchar(max)
	DECLARE @query nvarchar(max)
	DECLARE @queryPageSize nvarchar(max)
	DECLARE @UnionData NVARCHAR(max)


set @GetData = '

		CREATE TABLE #tblPermission (id uniqueidentifier primary key )
		INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Sal_UnusualPay'''+'


		select s.* into #Hre_Profile from Hre_Profile s join #tblPermission tb on s.ID = tb.ID
		where isdelete is null -- '+@MonthYear+'

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

'

SET @query=
'			
		-----------------------Lay du lieu tu bang Luong---------------------------
		;WITH List_emp_costcentre_root AS
		(
		select 
					hp.ID AS ProfileID , hp.CodeEmp, hp.ProfileName
					,cou.E_BRANCH AS DivisionName, cou.E_UNIT AS CenterName, cou.E_DIVISION AS DepartmentName, cou.E_DEPARTMENT AS SectionName, cou.E_TEAM AS UnitName
					--,ISNULL(neorg.DivisionName,'' '') AS DivisionName ,ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
					--,ISNULL(neorg.DivisionOrder,'' '') AS DivisionOrder ,ISNULL(neorg.CenterOrder,'' '') AS CenterOrder , ISNULL(neorg.DepartmentOrder,'' '') AS DepartmentOrder ,ISNULL(neorg.SectionOrder,'' '') AS SectionOrder,ISNULL(neorg.UnitOrder,'' '') AS UnitOrder
					--,ISNULL(cet.EN,'' '') AS EmploymentTypeGroup
					,cost.CostCentreName,cat.Code AS CostSourceName
					,csc.SalaryClassName
					,ROW_NUMBER() OVER(PARTITION BY hp.ID ORDER BY hwh.DateEffective DESC) AS rk
		FROM		Hre_Profile hp
		LEFT JOIN	Hre_WorkHistory hwh
			ON		hp.ID = hwh.ProfileID 
		LEFT JOIN	Cat_OrgStructure cos 
			ON		cos.ID = hwh.OrganizationStructureID
		LEFT JOIN	Cat_SalaryClass csc
			ON		csc.ID = hwh.SalaryClassID
		LEFT JOIN	Cat_AbilityTile cat
			ON		cat.ID = csc.AbilityTitleID
		LEFT JOIN	Cat_CostCentre cost
			ON		cost.ID = hwh.CostcentreID
		LEFT JOIN	Cat_OrgUnit cou
			ON		cou.OrgstructureID = hwh.OrganizationStructureID AND cou.Isdelete IS NULL
		--LEFT JOIN	#NameEnglishORG neorg
		--	ON		neorg.OrgStructureID = hwh.OrganizationStructureID
		WHERE		hwh.IsDelete is null
			AND		hwh.DateEffective <= @DateEnd
			AND		hwh.Status = ''E_APPROVED''
			AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart )
			AND		hp.DateHire <= @DateEnd
					'+ISNULL(@condition,'')+'
					'+ISNULL(@EmStatus,'')+'
		)

		Select		lec.ProfileID, lec.CodeEmp, lec.ProfileName, lec.DivisionName, lec.CenterName,lec.DepartmentName, lec.SectionName,lec.UnitName, lec.SalaryClassName, lec.CostSourceName, lec.CostCentreName
					,lec.DivisionName AS DivisionName_COM , lec.CenterName AS CenterName_COM ,lec.DepartmentName AS DepartmentName_COM , lec.SectionName AS SectionName_COM ,lec.UnitName AS UnitName_COM , lec.SalaryClassName AS SalaryClassName_COM , lec.CostSourceName AS CostSourceName_COM, lec.CostCentreName AS CostCentreName_COM
					,CONVERT(DECIMAL(12,2),1) AS Rate, NULL AS DateEffectFrom, NULL AS DateEffectTo, 0 As IsRoot

		into		#List_emp_costcentre_root
		from		List_emp_costcentre_root lec
		where		LEC.rk = 1

		
'
SET @UnionData =
'	
		SELECT		lecr.*, NULL AS STT
		INTO		#List_emp_costcentre_share
		FROM		#List_emp_costcentre_root lecr
		UNION
					( 
					SELECT		sccs.ProfileID, lec.CodeEmp, lec.ProfileName, lec.DivisionName, lec.CenterName,lec.DepartmentName, lec.SectionName,lec.UnitName, lec.SalaryClassName, lec.CostSourceName, lec.CostCentreName
								,cou.E_BRANCH AS DivisionName_COM , cou.E_UNIT AS CenterName_COM ,cou.E_DIVISION AS DepartmentName_COM , cou.E_DEPARTMENT AS SectionName_COM ,cou.E_TEAM AS UnitName_COM 
								, lec.SalaryClassName AS SalaryClassName_COM , lec.CostSourceName AS CostSourceName_COM, cost.CostCentreName AS CostCentreName_COM
								, CONVERT(DECIMAL(12,2),sccs.Rate/100) AS Rate, sccs.DateStart AS DateEffectFrom, sccs.DateEnd AS  DateEffectTo
								, ROW_NUMBER() OVER(PARTITION BY sccs.ProfileID ORDER BY sccs.Rate DESC) AS IsRoot, NULL AS STT
					FROM		Sal_CostCentreSal sccs
					LEFT JOIN	Cat_OrgUnit Cou
						ON		Cou.OrgstructureID = sccs.OrgStructureID
					LEFT JOIN	Cat_CostCentre Cost
						ON		Cost.ID = sccs.CostcentreID
					INNER JOIN	#List_emp_costcentre_root lec
						ON		lec.ProfileID = sccs.ProfileID
					WHERE		sccs.DateStart <= @DateEnd AND ( sccs.DateEnd >= @DateStart OR sccs.DateEnd IS NULL )
								AND sccs.IsDelete IS NULL
					)

		SELECT		*, @StartMonth AS "MonthYear", ROW_NUMBER() OVER ( ORDER BY ProfileName,IsRoot, DivisionName, CenterName,DepartmentName, SectionName,UnitName,CodeEmp ) as RowNumber
					,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "hwh.EmploymentType",NULL AS "hwh.SalaryClassID" ,NULL AS "hwh.PositionID", NULL AS "hwh.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "hwh.WorkPlaceID"
					,NULL AS "hwh.EmployeeGroupID", NULL AS "hwh.LaborType", NULL AS "hwh.CostCentreID", NULL AS "csc.AbilityTitleID", NULL AS "AmountCondittion"
					,NULL AS "PayPaidType", NULL AS "BankName", NULL AS "GroupBank"
					,NULL AS "EmpStatus",NULL AS "IsSalary", NULL AS "IsNotSalary", NULL AS "IsSalaryBanking"
		INTO		#Results
		FROM		#List_emp_costcentre_share

		---Tinh tong Phan bo cua tung nguoi
		SELECT		CodeEmp, Sum(Rate) AS SumRateShare
		INTO		#SumRateShare
		FROM		#Results
		WHERE		IsRoot <> 0
		GROUP BY	CodeEmp

		----Update lai rate cho dong thong tin goc
		UPDATE		r
		SET			r.Rate =  CASE WHEN 1 - ISNULL(s.SumRateShare,0) > 0 THEN 1 - ISNULL(s.SumRateShare,0) ELSE 0 END
		FROM		#Results r
		INNER JOIN	#SumRateShare s
			ON		r.CodeEmp = s.CodeEmp
		WHERE		r.IsRoot = 0

		--- upadte dong phan bo bang null khi dong thong tin goc co rate > 0
		UPDATE		#Results
		SET			CodeEmp = NULL, ProfileName = NULL, DivisionName = NULL, CenterName = NULL ,DepartmentName = NULL, SectionName = NULL,UnitName = NULL , SalaryClassName = NULL, CostSourceName = NULL, CostCentreName = NULL
		WHERE		CodeEmp IN 
					( SELECT CodeEmp FROM #Results WHERE IsRoot = 0 AND Rate <> 0)
					AND IsRoot <> 0

		---- update dong phan bo thu 3 tro len = null khi dong goc = 0
		UPDATE		#Results
		SET			CodeEmp = NULL, ProfileName = NULL, DivisionName = NULL, CenterName = NULL ,DepartmentName = NULL, SectionName = NULL,UnitName = NULL , SalaryClassName = NULL, CostSourceName = NULL, CostCentreName = NULL
		WHERE		CodeEmp IN 
					( SELECT CodeEmp FROM #Results WHERE IsRoot = 0 AND Rate = 0)
					AND IsRoot > 1

		---- Xoa dong goc neu Rate = 0
		DELETE		#Results WHERE IsRoot = 0 AND Rate = 0

		---- Tao STT ngoai tru dong NULL
		SELECT		*,ROW_NUMBER() OVER ( ORDER BY ProfileName,IsRoot, DivisionName, CenterName,DepartmentName, SectionName,UnitName,CodeEmp ) AS STT2
		INTO		#TempSTT
		FROM		#Results
		WHERE		CodeEmp IS NOT NULL AND ProfileName IS NOT NULL


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


		SELECT *, GETDATE() AS DateExport 
		FROM	#Results
		WHERE RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
		ORDER BY RowNumber


		DROP TABLE #Results
		drop table #tblPermission
		DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG
		DROP TABLE #List_emp_costcentre_root, #List_emp_costcentre_share, #SumRateShare

		'
	print ( @GetData)
	PRINT( @query)
	PRINT( @UnionData)
	PRINT(@queryPageSize )

	exec( @GetData +@query + @UnionData + @queryPageSize )


END
--[rpt_list_Sal_CostCentre]

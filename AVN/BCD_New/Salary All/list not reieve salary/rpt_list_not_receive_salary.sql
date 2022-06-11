
ALTER proc [rpt_list_not_receive_salary]	
@condition nvarchar(max) = " and (MonthYear = '2021-04-01') ",
@PageIndex int = 1,
@PageSize int = 10000,
@Username varchar(100) = 'Khang.Nguyen'
as
begin

	IF @condition = ' ' 
	begin
	set @condition =  ' and (MonthYear = ''2021-04-01'') '
	END

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
	DECLARE @MonthYearSP nvarchar(50) = ' '
	DECLARE @PayPaidType nvarchar(100) = ''
-- cat dieu kien


	while @row > 0
	begin
			set @index = 0
			set @ID = (select top 1 ID from #tableTempCondition)
			set @tempID = replace(@ID,'@',',')

			set @index = 0
			set @index = charindex('MonthYear = ',@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(MonthYear = ','(spt.MonthYear = ')
				set @tempCodition = 'and ('+@tempID
				set @MonthYear = @tempCodition
				SET @MonthYearSP = REPLACE(@tempCodition,'''','''''')
			end

			set @index = charindex('(GroupBank ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(Groupbank ','(cb.Groupbank ')
			end

			set @index = charindex('(ProfileID ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(ProfileID ','(spt.ProfileID ')
			end

			set @index = 0
			set @index = charindex('(OrderNumber ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(OrderNumber ','(cos.OrderNumber ')
			end

			set @index = charindex('(ProfileName ','('+@tempID,0) 
			if(@index > 0)
			begin
     			SET @condition = REPLACE(@condition,'(ProfileName ','(hp.ProfileName ')
			END

			set @index = charindex('(PayPaidType ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'AND ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @PayPaidType = @tempCodition
			END

			DELETE #tableTempCondition WHERE ID = @ID
			set @row = @row - 1

			END

-- Hình thức thanh toán
IF (@PayPaidType is not null AND @PayPaidType != '')
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

	declare @query nvarchar(max)
	declare @query2 nvarchar(max)
	declare @queryPageSize nvarchar(max)
	DECLARE @InsertTable NVARCHAR(max)
	SET @InsertTable = '
	CREATE TABLE #CountLeaveDay ( ProfileID uniqueidentifier primary key, ReasonLeave NVARCHAR(100))
	INSERT INTO #CountLeaveDay EXEC Countleaveday_EachEmployee '''+@MonthYearSP+''',0

	'

set @query = '
			
		CREATE TABLE #tblPermission (id uniqueidentifier primary key )
		INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''', '+'''Sal_PayrollTable'''+'

		--------------------------------Lay bang luong chinh-------------------------------------
		select s.* into #PayrollTable from Sal_PayrollTable s join #tblPermission tb on s.ProfileID = tb.ID
		where isdelete is null '+@MonthYear+'


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
--[rpt_list_not_receive_salary]	
SET @query2= N'
		-----------------------Lay du lieu tu bang Luong---------------------------
		;WITH Sal_PayrollTable_New AS
		(
		select 
					spt.ProfileID , hp.CodeEmp, hp.ProfileName,spt.MonthYear
					--,cou.E_BRANCH AS Division, cou.E_UNIT AS Center, cou.E_DIVISION AS Department, cou.E_DEPARTMENT AS Section, cou.E_TEAM AS Unit,
					,ISNULL(neorg.DivisionName,'' '') AS DivisionName ,ISNULL(neorg.CenterName,'' '') AS CenterName, ISNULL(neorg.DepartmentName,'' '') AS DepartmentName ,ISNULL(neorg.SectionName,'' '') AS SectionName,ISNULL(neorg.UnitName,'' '') AS UnitName
					,ISNULL(neorg.DivisionOrder,'' '') AS DivisionOrder ,ISNULL(neorg.CenterOrder,'' '') AS CenterOrder , ISNULL(neorg.DepartmentOrder,'' '') AS DepartmentOrder ,ISNULL(neorg.SectionOrder,'' '') AS SectionOrder,ISNULL(neorg.UnitOrder,'' '') AS UnitOrder
					,csct.SalaryClassName,ISNULL(cetl.EN,'' '') AS EmploymentType, cptl.PositionName AS PositionName , cjttl.JobTitleName AS JobTitleName,cwptl.WorkPlaceName AS WorkPlaceName, hp.DateHire AS DateHire,
					CASE WHEN cld.ReasonLeave <>'''' THEN '' + The unpaid leave days: '' +''"''+ cld.ReasonLeave + ''"'' + CHAR(13) ELSE '''' END +
					CASE WHEN spt.ID IS NULL THEN N'' + Absence in advance sheet'' + CHAR(13) ELSE '''' END AS ReasonOfADVANCE
					, dbo.VnrDecrypt(spti.E_Value) as Amount,spt.ID as PayrollTableID ,CASE WHEN spt.IsCash = 1 THEN N''Tiền Mặt'' ELSE N''Chuyển khoản'' END AS PayPaidType
					, ROW_NUMBER() OVER(PARTITION BY spt.ProfileID ORDER BY hwh.DateEffective DESC) AS rk
		FROM		Hre_Profile hp
		LEFT JOIN	SAl_PayrollTable spt
			ON		hp.id= spt.ProfileID and hp.IsDelete is null AND spt.Isdelete IS NULL
		LEFT JOIN	Hre_WorkHistory hwh 
			ON		spt.ProfileID = hwh.ProfileID 
		LEFT JOIN	Cat_OrgStructure cos 
			ON		cos.ID = spt.OrgstructureID
		LEFT JOIN	Cat_SalaryClass_Translate csct
			ON		csct.OriginID = hwh.SalaryClassID
		LEFT JOIN	Cat_NameEntity cne
			ON		cne.ID = hwh.CostSourceID
		LEFT JOIN	#NameEnglishORG neorg 
			ON		neorg.OrgStructureID = spt.OrgStructureID
		LEFT JOIN	Cat_Position_Translate cptl
			ON		cptl.OriginID = spt.PositionID
		LEFT JOIN	Cat_JobTitle_Translate cjttl
			ON		cjttl.OriginID = spt.JobTitleID
		LEFT JOIN	Cat_WorkPlace_Translate cwptl
			ON		cwptl.OriginID = spt.WorkPlaceID
		LEFT JOIN	Sal_PayrollTableItem spti
			ON		Spti.PayrollTableID = spt.ID AND spti.Code = ''AVN_NetIncome''
		LEFT JOIN	#CountLeaveDay cld
			ON		cld.ProfileID = hp.ID
		OUTER APPLY (
					SELECT	TOP(1) cetl.EN, cetl.VN
					FROM	Cat_EnumTranslate cetl
					WHERE	cetl.EnumKey = hwh.EmploymentType 
							AND cetl.EnumName = ''EmploymentType'' AND cetl.IsDelete is null
					ORDER BY DateUpdate
					) cetl
		WHERE		hwh.IsDelete is null
			AND		hwh.DateEffective <= @DateEnd
			AND		hwh.Status = ''E_APPROVED''
			AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart)
			'+ISNULL(@condition,'')+'
		)
		Select *
		into #Sal_Payrolltable_New
		from Sal_PayrollTable_New 
		where rk = 1 
		AND ( Amount = 0 OR PayrollTableID IS NULL )
		'+ISNULL(@PayPaidType,'')+' 

		UPDATE		#Sal_Payrolltable_New
		SET			ReasonOfADVANCE = CASE WHEN LEN(ReasonOfADVANCE) > 1 THEN SUBSTRING(ReasonOfADVANCE,1,LEN(ReasonOfADVANCE)-1) ELSE ReasonOfADVANCE END

		SELECT		*, ROW_NUMBER() OVER ( ORDER BY DivisionName,DivisionOrder, CenterName,CenterOrder,DepartmentName,DepartmentOrder, SectionName,SectionOrder ,EmploymentType ,ProfileName ) as RowNumber, NULL AS "sup.MonthYear"
					,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "hwh.EmploymentType",NULL AS "hwh.SalaryClassID" ,NULL AS "hwh.PositionID", NULL AS "hwh.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "hwh.WorkPlaceID",NULL AS "spt.EmpStatus", NULL AS "AmountCondittion"

		INTO		#Results
		FROM		#Sal_Payrolltable_New
		'
set @queryPageSize = ' 

		ALTER TABLE #Results ADD TotalRow int
		declare @totalRow int
		SELECT @totalRow = COUNT(*) FROM #Results
		update #Results set TotalRow = @totalRow
		SELECT *, GETDATE() AS DateExport
		FROM #Results 
		WHERE RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
		ORDER BY RowNumber
		DROP TABLE #Results
		drop table #tblPermission
		drop table #Sal_Payrolltable_New
		DROP TABLE #UnitCode,#NamEnglish1,#NamEnglish ,#NameEnglishORG
		'
	print (@InsertTable + @query +@query2+ @queryPageSize )

	exec(@InsertTable + @query +@query2 + @queryPageSize )


END
--[rpt_list_not_receive_salary]
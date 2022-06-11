Alter proc [dbo].[rpt_Advance_payroll_banking]
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
	DECLARE @Amount NCHAR(100)
	declare @conditionCutOffDurationID varchar(100)
	set @conditionCutOffDurationID = ''
	DECLARE @MonthYear nvarchar(50) = ' '
	DECLARE @MonthYearSP nvarchar(50) = ' '
	DECLARE @AmountCondittion nvarchar(100) = ''
	DECLARE @PayPaidType nvarchar(100) = ''

	
	while @row > 0
	begin
			set @index = 0
			set @ID = (select top 1 ID from #tableTempCondition)
			set @tempID = replace(@ID,'@',',')

			set @index = 0
			set @index = charindex('MonthYear = ',@tempID,0) 
			if(@index > 0)

			begin
				set @condition = REPLACE(@condition,'(MonthYear = ','(sup.MonthYear = ')
				set @tempCodition = 'AND ('+@tempID
				set @MonthYear = @tempCodition
				SET @MonthYearSP = REPLACE(@tempCodition,'''','''''')
			end

			set @index = charindex('(GroupBank ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(Groupbank ','(cb.Groupbank ')
			end

			set @index = charindex('(BankName ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(BankName ','(cb.BankName ')
			end

			set @index = charindex('(ProfileID ','('+@tempID,0) 
			if(@index > 0)
			begin
				set @condition = REPLACE(@condition,'(ProfileID ','(sup.ProfileID ')
			END
			
            
			set @index = charindex('(Amount ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
            	--set @condition = REPLACE(@condition,'(Amount ','(spt.Amount ')
				set @tempCodition = 'AND ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @Amount = @tempCodition
			END
            
			
			set @index = charindex('(AmountCondittion ','('+@tempID,0) 
			if(@index > 0)
			BEGIN
				set @tempCodition = 'AND ('+@tempID
				set @condition = REPLACE(@condition,@tempCodition,'')
				set @AmountCondittion = REPLACE(@tempCodition,'(AmountCondittion in ','')
				set @AmountCondittion = REPLACE(@AmountCondittion,',',' OR ')
				set @AmountCondittion = REPLACE(@AmountCondittion,'))',')')
			END

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
--- Giá trị
IF (@AmountCondittion is not null and @AmountCondittion != '')
BEGIN
	SET @index = charindex('E_EqualToZero',@AmountCondittion,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondittion = REPLACE(@AmountCondittion,'''E_EqualToZero''','Amount = 0')
	END
	SET @index = charindex('E_LessThanZero',@AmountCondittion,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondittion = REPLACE(@AmountCondittion,'''E_LessThanZero''','Amount < 0')
	END
	SET @index = charindex('E_GreaterThanZero',@AmountCondittion,0) 
	IF(@index > 0)
	BEGIN
	SET @AmountCondittion = REPLACE(@AmountCondittion,'''E_GreaterThanZero''','Amount > 0')	
	END
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
	declare @queryPageSize nvarchar(max)


set @query = '
		CREATE TABLE #tblPermission (id uniqueidentifier primary key )
		INSERT INTO #tblPermission EXEC Get_Data_Permission_New '''+@Username+''',''Sal_UnusualPay''
		
		
		--- Lay ngay bat dau va ket thuc ky luong
		DECLARE @DateStart DATETIME, @DateEnd DATETIME, @StartMonth  DATETIME
		SELECT @DateStart = DateStart , @DateEnd = DateEnd,  @StartMonth = MonthYear FROM Att_CutOffDuration WHERE IsDelete IS NULL '+@MonthYear+'

		---Ngay ket thuc ky ung
		DECLARE @UnusualDay INT
		DECLARE @DateEndAdvance DATETIME

		SELECT @UnusualDay = value1 from Sys_AllSetting WHERE isdelete is null AND Name like ''%AL_Unusualpay_DaykeepUnusualpay%''
		SET @DateEndAdvance = DATEADD(DAY,@UnusualDay -1,@StartMonth)
				
		-----------------------Lay du lieu tu bang Luong--------------------------- [rpt_Advance_payroll]
		;WITH Sal_UnusualPay_New AS
		(
		select 
					sup.ProfileID , hp.CodeEmp,hp.ProfileName, hp.NameEnglish, sup.AccountNo,cb.BankName + '', '' + ISNULL(supi2.Amount,'''') AS BankBranhName , cb.BankName, supi2.Amount as BranchName, supi.Amount AS PayPaidType
					,CASE WHEN cb.GroupBank IN(''ICB'', ''BIDV'', ''VCB'',''NN'') THEN ISNULL(cb.BankName,''NULL'') ELSE ISNULL(cb.GroupBank,''NULL'') END AS GroupBankName ,cb.GroupBank
					,sup.Amount as Amount , sup.BankID, Sup.MonthYear, GETDATE() AS DateExport
					,hwh.SalaryClassID, ROW_NUMBER() OVER(PARTITION BY sup.ProfileID ORDER BY hwh.DateEffective DESC) AS rk
		FROM		Sal_UnusualPay sup
		LEFT JOIN	Hre_WorkHistory hwh 
			ON		sup.ProfileID = hwh.ProfileID 
		LEFT JOIN	Hre_Profile hp 
			ON		hp.id= sup.ProfileID AND hp.IsDelete is null
		LEFT JOIN	Cat_Bank cb 
			ON		cb.ID = sup.BankID AND cb.IsDelete IS  NULL
		LEFT JOIN	Cat_OrgStructure cos 
			ON		cos.ID = sup.OrgstructureID AND	cos.Isdelete IS NULL
		LEFT JOIN	Sal_UnusualPayItem supi
			ON		supi.UnusualPayID = sup.ID 
					AND supi.Code = ''SAL_SALARYINFORMATION_ISCASH_BYUNUSUALPAY'' AND supi.Isdelete IS NULL
		LEFT JOIN	Sal_UnusualPayItem supi2
			ON		supi2.UnusualPayID = sup.ID 
					AND supi2.Code = ''SAL_SALARYINFORMATION_BRANCHNAME1'' AND supi2.Isdelete IS NULL
		--INNER JOIN	#tblPermission tbl on tbl.id = spt.ProfileID
		WHERE		hwh.IsDelete is null
			AND		hwh.DateEffective <= @DateEndAdvance
			AND		hwh.Status = ''E_APPROVED''
			AND		( hp.DateQuit IS NULL OR hp.DateQuit >= @DateStart )
			AND		sup.Isdelete IS  NULL
			'+ISNULL(@condition,'')+'
		)
		Select *
		into #Sal_UnusualPay_New 
		from Sal_UnusualPay_New 
		WHERE rk = 1 
		--'+ISNULL(@Amount,'') +' 
		'+ISNULL(@AmountCondittion,'')+' 
		'+ISNULL(@PayPaidType,'')+' 


		Update	#Sal_UnusualPay_New 
		Set		GroupBankName = (SELECT DISTINCT BankName FROM dbo.Cat_Bank WHERE GroupBank = ''VCB'' AND IsDelete IS NULL)
		WHERE	GroupBank = ''VCB Others''

		select		*,ROW_NUMBER() OVER ( ORDER BY GroupBankName,BankName,BranchName,BankBranhName asc) as RowNumber
					,NULL AS "hp.CodeEmp",NULL AS "cos.OrderNumber",NULL AS "hwh.EmploymentType",NULL AS "hwh.SalaryClassID" ,NULL AS "hwh.PositionID", NULL AS "hwh.JobTitleID", NULL AS "hp.DateHire", NULL AS "hp.DateEndProbation", NULL AS "hp.DateQuit",NULL AS "hwh.Wor
kPlaceID",NULL AS "sup.EmpStatus", NULL AS "AmountCondittion"
		INTO		#Results 
		FROM		#Sal_UnusualPay_New 
					
		'
set @queryPageSize = ' 

		ALTER TABLE #Results ADD TotalRow int
		declare @totalRow int
		SELECT @totalRow = COUNT(*) FROM #Results
		update #Results set TotalRow = @totalRow
		SELECT *
		FROM #Results 
		WHERE RowNumber BETWEEN('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1 AND((('+CAST(@PageIndex AS varchar)+' -1) * '+CAST(@PageSize AS varchar)+' + 1) + '+CAST(@PageSize AS varchar)+') - 1
		ORDER BY RowNumber
						
		DROP TABLE #Results
		drop table #tblPermission
		drop table #Sal_UnusualPay_New
		'
	print (@query +' '+ @queryPageSize )
	exec(@query +' '+ @queryPageSize )
END

--[rpt_Advance_payroll_banking]
